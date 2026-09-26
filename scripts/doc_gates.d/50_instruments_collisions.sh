#@ scripts/doc_gates.d/50_instruments_collisions.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATE 15 (instruments), GATE 16 (collisions) -- the two gates that read this suite's own source.
#@ Lines 9190-11216 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# ----------------------------------------------------------------------------------
# GATE 15 — a new instrument in the --selftest region cannot land silent (ITEM A1, 2026-08-02).
#
# WHY THIS EXISTS, and why it is a gate rather than a resolution. `_selftest_revert` shipped
# at fbdbe26 with no fire-proof, in the one file whose header already records GATE 8 shipping
# a one-directional comparison behind a hand-taken proof. It was caught only because someone
# checked that commit message's claim against a run — and the claim was false (the ref
# resolved and its reflog held ZERO entries). That is the THIRD instance of one class in this
# file: GATE 8's hand-taken proof, GATE 4b's shared dispatch, and now this. Three instances
# of the same shape is a structural hole, and "be more careful" has already been tried.
#
# WHAT IT DOES. Enumerates every function DEFINED between the `--selftest` guard and its
# closing `fi`, and requires a row for each in documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt
# naming the assertion that proves it — or the explicit token NOT-PROVEN-IN-HARNESS with a
# reason. A declared label must actually occur in this file, so a row cannot point at an
# assertion nobody wrote.
#
# IT RUNS IN `all`, NOT ONLY IN --selftest, AND THAT IS THE POINT. The self-test needs a
# clean tree and takes minutes; a helper added during a normal edit would not meet it for
# hours. This gate is a text scan of one file and costs milliseconds.
#
# THE PARSER MUST NOT SILENTLY FIND NOTHING. If the region markers move, a naive scan
# returns zero functions and every row looks stale while nothing looks undeclared — a green
# run with the instrument switched off. Finding zero functions is therefore a FAIL, stated
# here because that is exactly the failure mode of the checker whose false clear hid a Lean
# defect for twelve hours on 2026-08-01.
#
# WHAT IT CANNOT SEE, said plainly (the full version is in the table's own header):
#   (a) It verifies that the function exists and that the named label exists. It CANNOT
#       verify the named assertion exercises the function. A row pointing at a real but
#       unrelated label passes. This is bookkeeping with a spell-check, not coverage proof.
#       The label search is over the WHOLE file, so a label that appears only in a comment,
#       or only inside another assertion's mutation string, satisfies it. That is not
#       hypothetical: this gate's own second fire-proof failed for exactly that reason on
#       its first run and had to assemble its substitute label from fragments.
#       AND THE BLIND SPOT HAD AN INSTANCE IN THIS GATE'S OWN FIRST ROW SET, found by the
#       row-by-row audit in round 8 (item A3): `scratch_appendonly` declared the label of a
#       real assert_fires_why that mutates the live repo and never calls it. Shipped with
#       the gate at 6d93ed5, green the whole time, re-pointed 2026-08-02. The audit's full
#       classification of all 10 rows — and why the cheap mechanical rule cannot ship as a
#       blanket FAIL — is in the table's caveat (1).
#   (b) --selftest region only. Helpers inside gate bodies are gate implementation and are
#       covered by the gates' own fire-proofs.
#   (c) It cannot rank proofs. `assert_fires_why`'s anchor-moved branch is exercised by
#       nothing; its row says so in prose that no machine reads.
gate_selftest_instruments() {
  echo "== GATE 15: every --selftest instrument declares the assertion that proves it =="
  local tbl=documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt rct=0
  require_tracked "$tbl" \
    "The declaration table IS this gate; absent, every instrument reads as declared." || rct=$?
  [ "$rct" -eq 1 ] && return 0
  [ "$rct" -eq 2 ] && return 1
  DOC_GATES_INSTR_TBL="$tbl" python3 - <<'PY'
import os, re, subprocess, sys

# READ-ONLY SOURCE SEAM, and it exists for one reason that is worth stating because a
# testing backdoor in a gate deserves suspicion. The mutation this gate must be proven
# against is "a new function appears in the --selftest region" — and the file that would
# have to be mutated is THIS ONE, the script bash is currently executing. Task #77 is open
# on exactly that hazard (bash reads scripts by byte offset), and a fire-proof that risks
# leaving a half-restored doc_gates.sh behind is not worth the assurance. So the fire-proof
# mutates a COPY and points the scan at it, which is the same thing every other assertion in
# this file does — mutate the gate's input — the input here just happens to be the program.
# The seam is READ-ONLY (the file is scanned, never executed, never written) and an override
# is ANNOUNCED below, so it cannot quietly weaken a real run.
src = os.environ.get("DOC_GATES_SRC_OVERRIDE") or "scripts/doc_gates.sh"
if src != "scripts/doc_gates.sh":
    print("  [note] scanning OVERRIDE source %s (DOC_GATES_SRC_OVERRIDE), not the live script"
          % src)
if not os.path.isfile(src):
    print("  [FAIL] %s is not a readable file, so zero instruments were scanned" % src)
    sys.exit(1)
lines = (open(src, encoding="utf-8").read() if src != "scripts/doc_gates.sh" else subprocess.run(["bash", "scripts/doc_gates.d/logical_source.sh"], stdout=subprocess.PIPE, check=True).stdout.decode("utf-8")).splitlines()

start = end = None
for i, ln in enumerate(lines):
    if start is None and '= "--selftest" ]; then' in ln:
        start = i
    elif start is not None and ln == "fi":
        end = i
        break
if start is None or end is None:
    print("  [FAIL] could not locate the --selftest region in %s (start=%s end=%s)"
          % (src, start, end))
    print("         The scan would have returned zero functions and reported [ok] on an")
    print("         instrument that was switched off. Re-anchor this gate, do not silence it.")
    sys.exit(1)

# CODEX N10 FINDING 11, adjudicated 2026-09-03: the claim above is "every function DEFINED
# between the --selftest guard and its closing fi", and the matcher recognised exactly ONE of
# bash's three spellings, `name() {`. A `function unproved { ... }` or a `unproved () { ... }`
# helper — both valid bash, both would run — was invisible to the enumeration and therefore
# needed no declaration row. That is the same shape as finding 9 (a population keyed on a
# convention rather than on the thing itself), and the caveat list below did not admit it.
#
# All three spellings now match. MEASURED before landing, over the live --selftest region
# (lines 2973-6856): old matcher 12 functions, new matcher 12 functions, NEW-ONLY set empty,
# OLD-ONLY set empty — and zero occurrences of either alternative spelling anywhere in the
# 17k-line file. So this widens the population by nothing today and cannot start failing on
# existing content; it closes the hole for the next helper somebody writes the other way.
# GATE 15's instrument count is an ABSOLUTE claim on the selftest-instruments scoreboard, and
# it is unmoved at 12.
DEF = re.compile(r"^[ \t]*(?:"
                 r"function[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]*(?:\(\)[ \t]*)?"  # function f {  / function f() {
                 r"|([A-Za-z_][A-Za-z0-9_]*)[ \t]*\(\)[ \t]*"                    # f() {  / f () {
                 r")\{")
defined = {}
for i in range(start + 1, end):
    m = DEF.match(lines[i])
    if m:
        defined[m.group(1) or m.group(2)] = i + 1

if not defined:
    print("  [FAIL] zero functions found in the --selftest region (lines %d-%d), which is"
          % (start + 1, end + 1))
    print("         a broken parser, not an empty harness. A checker that finds nothing must")
    print("         never report [ok].")
    sys.exit(1)

path = os.environ["DOC_GATES_INSTR_TBL"]
rows = {}
bad = 0
for lineno, line in enumerate(open(path, encoding="utf-8"), 1):
    if not line.strip() or line.lstrip().startswith("#"):
        continue
    parts = line.rstrip("\n").split("\t")
    if len(parts) < 4 or not all(p.strip() for p in parts[1:4]):
        print("  [FAIL] %s:%d is not `function<TAB>proof-label<TAB>claims<TAB>note`, so it"
              " declares nothing" % (path, lineno))
        print("         The claims column landed 2026-08-02 (round 9, items B8 + B3). A row")
        print("         in the old three-column shape carries no kind= and no callers=, and")
        print("         would be waved through by a parser that tolerated it.")
        bad = 1
        continue
    rows[parts[0]] = (parts[1], parts[2], parts[3], lineno)

whole = "\n".join(lines)
for name in sorted(defined):
    if name not in rows:
        print("  [FAIL] %s() is defined at %s:%d and is declared in NO row of %s"
              % (name, src, defined[name], path))
        print("         A new instrument in this harness lands with a fire-proof or lands")
        print("         declared as unprovable. `_selftest_revert` landed as neither"
              " (fbdbe26),")
        print("         and its commit message asserted a property it did not have.")
        bad = 1
        continue
    label, claims, note, lineno = rows[name]
    if label == "NOT-PROVEN-IN-HARNESS":
        print("  [note] %s() is declared UNPROVABLE in-harness (%s:%d) — %s"
              % (name, path, lineno, note.split(".")[0]))
    elif label not in whole:
        print("  [FAIL] %s:%d says %s() is proven by \"%s\", and that label does not occur"
              % (path, lineno, name, label))
        print("         anywhere in %s. The declared proof does not exist." % src)
        bad = 1

for name in sorted(rows):
    if name not in defined:
        print("  [FAIL] %s:%d declares %s(), which is no longer defined in the --selftest"
              " region" % (path, rows[name][3], name))
        print("         A row for a function nobody calls exempts nothing and hides that it")
        print("         exempts nothing. Delete the row.")
        bad = 1

# --- LEG 2 (ITEM A2, round 8 drain-2, 2026-08-02): a fire-proof that searches a COPY of
# this script must match on a form its own source lines cannot take.
#
# THE MOTIVATING EXAMPLE WAS LIVE WHEN THIS WAS WRITTEN, not historical. GATE 15's own
# first fire-proof built its copy with `sed` and confirmed the injection with an
# unanchored `grep -qF` for the injected literal — and `sed` reads THIS file, so the sed
# EXPRESSION carrying that literal was copied verbatim into the copy. The guard therefore
# succeeded on a copy in which nothing had been injected (measured: a deliberately moved
# anchor produced a byte-identical copy and the guard still passed). Item A2 lists five
# instances of this class across two days — GATE 15's label leg, GATE 16's vacuity leg,
# GATE 16's extractor, GATE 17 LEG 6's confirmation, and a stale-identifier sweep that
# matched itself and reported clean. Four of the five were caught by RUNNING, none by
# reading, and every fix was hand-applied at one site. This is the check on the class.
#
# THE RULE IS ITEM A2's SECOND FORM, the one that is mechanical: the confirmation must
# anchor on a form its own source cannot take. Concretely, a `grep -q` guard whose target
# is a `$..._COPY` of this script must (1) use an ERE (`-qE`) — a `-qF` fixed string
# cannot express an anchor at all — and (2) begin that ERE with `^`. Both live guards
# satisfy it; the pre-fix GATE 15 guard fails clause (1) and, with the `^` stripped,
# clause (2). Both directions are fire-proven in --selftest.
#
# IT CANNOT BE SATISFIED BY ITS OWN SOURCE, and that is DEMONSTRATED, not asserted —
# which is the whole point of the item. Two independent mechanisms:
#   * the pattern is written `grep\s+-q`, a form no line it searches for can take, so the
#     regex does not match its own definition (checked);
#   * the scan is bounded to the --selftest region, which excludes this gate body.
# The second is load-bearing TODAY and can be seen to be: caveat (v) below contains a
# literal `grep -qE "$PAT" "$_G15_COPY"` and the compiled pattern DOES match that line.
# It is excluded solely by the region bound. So if the region bound ever breaks, this gate
# flags its own documentation and goes RED — a loud failure, not the silent self-satisfying
# clear that item A2 catalogues five instances of. That is a standing proof rather than a
# claim, and it re-runs on every `all`.
#
# WHAT IT CANNOT SEE, stated because a clear is weaker than a failure:
#   (i)   `^` is NECESSARY, not sufficient. A source line that itself begins with the
#         guarded text at column 0 would still defeat an anchored guard. Neither live
#         guard has that shape (one starts `  if sed`, the other `     && !`), but this
#         gate does not check it.
#   (ii)  It sees `grep` guards only. A confirmation written in PYTHON — inside the builder
#         itself, as `assert len(t)==N` / `assert n>0` before the copy is written — is
#         outside the scan; those are item A2's FIRST form applied by hand. THE COUNT OF
#         SUCH LEGS IS DELIBERATELY NOT STATED: this caveat said "GATE 16's two legs" and
#         was stale twice over inside one day, which is the caveat-4 shape appearing in a
#         caveat. The SHAPE is what this points at; the population is re-measured below.
#   (iii) It says nothing about the MUTATION half: a mutation whose injected literal
#         collides with the corpus is item A2's other direction and is still hand-guarded
#         (`src.count(lbl)==1` in GATE 15's label leg).
#   (iv)  The scan is PER LINE, so a guard wrapped across a `\` continuation — `grep -q` on
#         one line, `"$_G15_COPY"` on the next — is invisible. MEASURED rather than left as
#         a worry, the way item A7's three-line window was: re-running this scan over
#         continuation-JOINED lines finds the same two guards and no third, so the blind
#         spot is real and currently empty. Two lines DO contain both tokens after joining
#         and are correctly not flagged — a comment and a [FAIL] message, both this leg's
#         own — which is also the evidence that the pattern discriminates. RE-MEASURED
#         2026-08-02 (item B10) after item B2 added four more fire-proofs: the joined scan
#         still finds the SAME TWO guards and no third. Re-taken from a run, not re-asserted
#         from the round-8 sentence — the blind spot is real and is still empty.
#   (v)   A guard whose pattern is a VARIABLE (`grep -qE "$PAT" "$_G15_COPY"`) is reported
#         as unanchored, because `$PAT` does not start with `^`. That is a false FAIL in the
#         conservative direction: this gate cannot follow an indirection, and refusing one
#         is better than clearing it. There are none today.
#   (vi)  CLOSED BY LEG 4 (item N4, round 10, 2026-08-02) — READ THIS ENTRY FOR THE HISTORY,
#         NOT FOR A NUMBER. The count THIS leg prints is still a FLOOR: deleting one of the
#         two anchored guards leaves the other and still prints [ok] with a smaller number.
#         Round 8 looked for a derived invariant to pin it against and found none, because the
#         `_COPY` VARIABLES are not in bijection with the guards — other legs confirm in
#         python instead. Round 9 found the thing that IS in bijection: copy BUILDERS. LEG 4
#         below now enforces "a copy may not be written without a confirmation of what went
#         into it" as coverage, so a deleted guard is a FAIL naming the builder that lost it
#         rather than a quieter count here.
#         NO POPULATION FIGURE IS STATED IN THIS COMMENT, DELIBERATELY. Round 9 recorded the
#         split as a number and the instruction "do not re-derive the 10/10 by hand", and
#         that instruction was not followable: only the COUNT was written down, and the
#         obvious definition of a builder — a shell redirect `> "$_*COPY"` plus an
#         `open('$_*COPY','w')` — returns SIX of the ten, silently. The four it misses write
#         through the environment, `open(os.environ['_*COPY'],'w')`. LEG 4 carries all three
#         syntaxes and PRINTS the per-syntax census every run, which is the durable form of
#         what this paragraph used to assert; a fourth syntax would still be invisible, and
#         a syntax falling to zero is now visible where the third one's absence was not.
#   (vii) It sees `grep -q` only. A confirmation written as `grep -c`, `[ -n "$(grep …)" ]`
#         or a `case` on file contents is outside the scan. Measured 2026-08-02 (item B10):
#         no confirmation in this region takes any of those three forms today, so (vii) is a
#         second real-and-currently-empty blind spot rather than an unmeasured one. It is
#         NOT the same hole as (ii) — (ii) is the PYTHON confirmation form. NO POPULATION
#         IS STATED HERE, and the reason is that one was: this sentence read `which is
#         populated at 8` from the day it was written (round 9), and LEG 4's own
#         fire-proofs then took that population to eleven without touching this line —
#         so the number was falsified by the same round's commits, in the same file,
#         ten lines from caveat (vi) which had just been rewritten to stop stating
#         populations. Caveat (ii) says outright that this count is deliberately not
#         stated; this line stated it anyway. THE LIVE FIGURE IS THE `N by an assert
#         earlier in the same python program` TERM OF LEG 4's [ok] LINE, which is
#         re-measured on every run and cannot go stale.
COPY_GUARD = re.compile(
    r"grep\s+-q([A-Za-z]*)\s+(?P<q>['\"])(?P<pat>.*?)(?P=q)[^&|;]*\$_[A-Za-z0-9_]*COPY")
guards = []
for i in range(start + 1, end):
    m = COPY_GUARD.search(lines[i])
    if m:
        guards.append((i + 1, m.group(1), m.group("pat")))

if not guards:
    print("  [FAIL] zero copy-confirmation guards found in the --selftest region (lines"
          " %d-%d)." % (start + 1, end + 1))
    print("         Two are known to exist (GATE 15's and GATE 17 LEG 6's). Finding none")
    print("         means the extractor stopped reading them, not that the harness stopped")
    print("         using them — a checker that finds nothing must never report [ok].")
    bad = 1

for lineno, flags, pat in guards:
    if "F" in flags:
        print("  [FAIL] %s:%d — this guard confirms an injection into a COPY of this script"
              " with a FIXED string:" % (src, lineno))
        print("           grep -q%s %s" % (flags, pat))
        print("         A fixed string cannot be anchored, and `sed`/`grep` build the copy")
        print("         FROM this file, so the guard's own source line is inside the copy it")
        print("         searches. It then passes with the injection switched off. Use -qE")
        print("         with a `^` anchor no line of the fire-proof itself can match.")
        bad = 1
    elif not pat.startswith("^"):
        print("  [FAIL] %s:%d — this guard's ERE is not anchored at line start:" % (src, lineno))
        print("           grep -q%s %s" % (flags, pat))
        print("         Unanchored, it also matches the fire-proof's own source line, which")
        print("         the copy contains verbatim. Anchor it with `^`.")
        bad = 1

# --- LEG 3 (ITEMS B8 + B3, round 9 drain-2, 2026-08-02): the claims column.
#
# WHAT IT REPLACES. Until today the only machine-read facts in a row were "this function
# exists" and "this label exists SOMEWHERE in doc_gates.sh". The table's caveat (1) recorded
# the consequence in its own first row set: `scratch_appendonly` named a real assertion that
# never called it, and the gate was green from 6d93ed5 until 2026-08-02. Round 8 offered two
# survivable designs — a reachability check, or a declared proof-KIND per row — and item B8
# names the second. Item B3's residue (an explicit `callers=N`) is the same format change, so
# it is taken here in one pass rather than twice.
#
# THE KINDS ARE THE THREE THE ROW-BY-ROW AUDIT MEASURED, not invented categories:
#   kind=INVOCATION  the label is the FIRST QUOTED ARGUMENT of a call to the declared
#                    function. Fully mechanical, and the strongest claim available: the label
#                    cannot then be satisfied by a comment or by another assertion's mutation
#                    string, which is what caveat (1a) is about.
#   kind=BLOCK       the label is echoed within BLOCK_WINDOW lines BELOW a call site of the
#                    declared function. Weaker, and it is the shape the three wrapper rows
#                    genuinely have (`_selftest_revert`, `_g13`, `_gsrc`).
#   kind=EXTERNAL    paired with NOT-PROVEN-IN-HARNESS, both directions enforced.
#
# THE STRONGEST SATISFIED KIND MUST BE DECLARED. A row saying BLOCK when the INVOCATION form
# holds is a FAIL — otherwise the column is an opt-out and a row could downgrade itself to
# escape the strict check, which is the ratchet every report-only gate in this file has had
# to argue about.
#
# THE CALL-SITE RULE IS ONE RULE, STATED ONCE, and it is stated in the table's header too so
# a row author can compute it. It counts the name in COMMAND POSITION — at line start, after
# `$(`, after `&&`/`||`/`;`/`|`/`then`/`else`/`do`, or opening a `trap` handler string —
# skipping comment lines and the function's own definition line.
#
# THAT RULE WAS MEASURED AGAINST THE HAND AUDIT, and it CORRECTED it. The table's caveat (4a)
# concluded "distinguishing the three requires a shell parse, not a grep" and published ten
# hand-adjudicated counts. This rule reproduces NINE of the ten exactly; on the tenth it says
# `_selftest_revert` has 24 call sites where the hand audit said 20. All 24 were read one by
# one, and two forms carry four calls each: `PASS=1; _selftest_revert; return; }` and
# `_selftest_revert; } \`. Every one is a real call. So the number that shipped as the reason
# a mechanical form was impossible was itself wrong, and the mechanical form is what found it.
#
# THE "MISSED" SET WAS OVERSTATED AND THE ARITHMETIC NEVER CLOSED (round 13 drain-2,
# 2026-08-02). This sentence used to say the weaker rules missed BOTH forms, "four of each" —
# that is 8 missed against a net gap of 24 - 20 = 4. Re-derived with the rule stated above:
# the four `PASS=1; …; return; }` calls are the ONLY ones not at line start, and all four
# `…; } \` calls ARE at line start, so any line-start rule already had the second form. Four
# missed, not eight, and they are the first form. WHAT THIS CANNOT SETTLE: the hand audit's
# METHOD was never written down, so "it counted the 20 at line start" is the reading that
# reconciles 20 -> 24, not a proven account of what the auditor did. The delta is measured;
# the explanation for it is inferred.
#
# HOW STRONG THAT INFERENCE IS — MEASURED, NOT ARGUED (round 13 drain-3, 2026-08-02). Applying
# "command position AND at line start, minus `_selftest_revert`'s own definition line" to the
# file selects exactly the hand audit's figure, and its complement WITHIN the command-position
# set is exactly the `PASS=1; …; return; }` calls and nothing else. It fits on MEMBERSHIP and
# not merely on the count, which is more than "inferred" concedes. WHAT IT STILL CANNOT DO:
# any rule with the same extension fits identically, and no rule was ever recorded, so this
# raises the inference's confidence without closing it. Re-derive with
# `grep -nE '^[[:space:]]*_selftest_revert' "$0"` and subtract the `() {` line.
#
# (Cited by FORM, not by line — the first draft of this comment named eight line numbers and
# its own commit invalidated them, which is item B1 happening inside the fix for item B8.)
#
# WHAT LEG 3 CANNOT SEE, stated because a clear is weaker than a failure:
#   (viii) BLOCK is PROXIMITY, not reachability — STILL TRUE, and it was NOT the worst of it.
#          A call followed within the window by a report line does not prove that line is on a
#          path the call reaches; it could sit in the `else`. Item B8's option (a), a `bash -x`
#          run with `PS4` carrying `$LINENO`, is the form that would close it. Round 10 drain-2
#          MEASURED that GATE 16 LEG 2's call-graph reader is NOT the reusable half — it maps
#          gate function to gate function and has no notion of statement position — so anyone
#          taking that route is starting from zero. The measured distance is printed every run
#          so a window that starts creeping is visible. NOT BUILT.
#
#          THE BLOCKER ON OPTION (a) IS GONE, MEASURED 2026-08-02 (round 11 drain-3). The
#          stated blocker was that the traced cost was UNKNOWN and so could not be run on this
#          box; it was never that the check would not work. `PS4='+${LINENO}:' bash -x` over
#          this script's `--selftest` produced 530,162 bytes / 6,314 lines of combined trace
#          and output in 1m57s wall — indistinguishable from the same run untraced — with
#          1,929 traced commands (1,550 at top level, 379 at subshell depth) and a clean tree
#          afterwards. No VM, no bound, nothing combinatorial. It was ALSO checked to PRODUCE
#          the observation rather than merely to be affordable: in one trace, every BLOCK row's
#          wrapper call and its `[ok]` report echo appear, in execution order, each carrying
#          `$LINENO`, and the DYNAMIC call-to-echo distances came out equal, row for row, to
#          the STATIC ones this leg already prints on its own `[ok]` line every run. (Those
#          distances are deliberately not repeated here: the leg prints them, and a caveat that
#          restates a live value is a corpus property written into the corpus, which is the one
#          way this paragraph could go stale in silence.) Two things a builder has to handle,
#          both observed and neither guessed: a wrapper reached only through `$(...)` traces
#          at subshell depth
#          (`++`, not `+`), and a wrapper is called more often than it reports (one is called
#          four times and echoes twice), so calls do NOT pair one-to-one with echoes.
#          THE BLOCKER MOVED TO THE FIRE-PROOF, AND THAT ONE IS STRUCTURAL — MEASURED
#          2026-08-02 (round 12 drain-1). The item's own fire-proof requirement is a report
#          line placed in an `else` the traced run never enters. THAT MUTATION CANNOT BE MADE
#          IN THIS WORKING TREE, and the thing that stops it is this script. Run with the
#          tree dirty:
#            PS4='+${LINENO}:' bash -x scripts/doc_gates.sh --selftest   ->  rc=2
#          and the trace ends at the cleanliness test that OPENS the --selftest block — the
#          FIRST test it makes — before a single gate runs. So the mutation dirties the tree,
#          the trace needs --selftest, and --selftest needs a clean tree. Round 11's
#          measurement was taken on a CLEAN tree, which is why six unit-attempts and that
#          measurement all missed this: it proved the traced run is affordable and that it
#          PRODUCES the observation — not that the leg can be FIRED.
#          TWO MORE WALLS BEHIND IT, both read off this file rather than guessed: the
#          --selftest block takes an exclusive mkdir lock and refuses a second holder, and a
#          depth guard sits behind the lock. A leg that spawns a traced --selftest from
#          INSIDE a running one is therefore refused, not recursed — which is a safety
#          property, and also means the trace-PRODUCING step can never live inside --selftest.
#          THE ROUTE THAT SURVIVES, AND IT IS NOT FREE: take the mutated traced run in a
#          linked `git worktree`. Tracked payload ~60 MB, measured — and the measuring
#          command is written out because a piped shorthand for it does NOT run (`du` takes
#          arguments, not stdin), which is the defect class this suite keeps finding:
#            git ls-files -z | xargs -0 du -cb | tail -1
#          DELIBERATELY NOT TESTED HERE. The revert path calls `git update-ref` on
#          refs/doc-gates/selftest-revert, which is NOT a per-worktree ref, so a worktree run
#          would repoint the MAIN tree's recovery anchor. That is survivable — the update
#          carries --create-reflog, so the prior snapshot still resolves through the reflog —
#          but it is a side effect on the main tree's recovery procedure, and it should be
#          DECIDED before it is done rather than discovered afterwards.
#          STILL NOT BUILT, and this does not weaken the sentence below it. A dynamic
#          call-then-echo adjacency proves both ran on ONE path, which static proximity cannot
#          — but it still does not prove the echo's verdict is ABOUT that call, and a trace
#          says nothing about the paths that run did not take.
#
#          WHAT WAS BUILT, because it was a hole underneath that one (item N3, round 10
#          drain-3, 2026-08-02). Until today the check asked whether the label OCCURRED on a
#          line within the window, and an occurrence is not an echo. In the live harness the
#          `_selftest_revert` row's satisfier was
#          `… | grep -q 'A1 snapshot probe'` — the marker text the assertion searches FOR,
#          which merely BEGINS with the row's label "A1 snapshot". So the strongest row on this
#          gate was proven by a string the harness never prints; as measured on 2026-08-02 the
#          printed `+3` was the distance to that grep and the `[ok]` line was at `+4`.
#          PROVEN BEFORE THE FIX, not argued: setting the row's label to the full probe marker
#          `A1 snapshot probe` — a string this harness ECHOES NOWHERE, which is the property
#          the fire-proof guards and the only one it needs — left LEG 3 GREEN at the identical
#          `_selftest_revert +3`. The fire-proof is that exact mutation, so the leg is proven
#          against the real defect and not a stylised one. It states no occurrence count on
#          purpose: the commit that first wrote one falsified it in the same diff, by writing
#          this paragraph.
#          The check now requires a REPORT line (see REPORT_ECHO), and the FAIL prints the
#          non-report occurrence it rejected, so the reason is in the output and not only here.
#          THIS IS NOT REACHABILITY AND MUST NOT BE DESCRIBED AS SUCH. A report line inside a
#          dead `else` still satisfies it.
#   (ix)   `callers=N` is a SYNTACTIC call-site count. It does not know which sites execute,
#          and it does not know what the note's prose means by its own number: caveat (4a)(ii)
#          measured that `assert_stays_clean_why`'s stated count of NEGATIVE CONTROLS is a
#          semantic SUBSET of its call sites, the difference being the `_asc_probe` PROBE.
#          THE TWO NUMBERS ARE NOT COPIED HERE (round 14, item R14). This sentence carried
#          them as "SIX" and "seven", and both were stale where they sat — a second-hand copy
#          of a caveat whose own copy had gone stale first, in a caveat about counts in prose
#          going stale. Cited by NAME: the authority is the ROW in
#          documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt, whose `callers=N` LEG 3 re-derives
#          every run. The column proves the total is current; the prose still
#          says what the total is made of, and nothing reads that.
#   (x)    The call rule does not parse heredocs or quoted blobs. A name in command position
#          inside a python `<<'PY'` body would be counted. There are none today (the rule
#          reproduces the hand audit), but it is a grep-shaped rule and it is not a shell.
#   (xi)   Because the FAIL prints the measured count, `callers=N` is cheap to satisfy by
#          copying the number the gate just printed. That makes it bookkeeping that cannot go
#          stale — which is exactly caveat (4)'s complaint — and nothing more.
BLOCK_WINDOW = 8
CALL_PRE = (r"(?:^[ \t]*|\$\([ \t]*|(?:&&|\|\||;|\||\bthen\b|\belse\b|\bdo\b)[ \t]*"
            r"|^[ \t]*trap[ \t]+['\"][ \t]*)")
CALL_POST = r"(?=[ \t;&|\"')]|$)"
# A REPORT LINE, which is what "the label is ECHOED below the call" was always supposed to
# mean and did not (item N3, round 10 drain-3, 2026-08-02 — see caveat (viii)). Every verdict
# this harness prints takes this one shape: `echo "  [marker] <label> …`, with the label
# starting immediately after the marker. Requiring the shape is what stops a line that merely
# CONTAINS the label — a grep pattern, a comment, a mutation string — from standing in for the
# assertion reporting.
#
# DECIDED 2026-08-02 (item R7, round 11 drain-1): `printf` IS NOT ACCEPTED, and the decision
# rests on a measurement rather than on the wording above. MEASURED over this script: every
# `printf` in it re-emits a CAPTURED VARIABLE through a pipe — `printf '%s\n' "$OUT" | sed`
# — as evidence under a verdict already written; not one of them writes an `[ok]`/`[FAIL]`
# marker itself. The two forms are doing different jobs here, so the rule is not merely
# accurate today, it matches how the harness is built. The count is not quoted: it moves, and
# the [ok] line prints the live distances every run.
# WIDENING IT WOULD BE A REGRESSION RISK, NOT A CONVENIENCE. A verdict written with `printf`
# is a FAIL under this rule — conservative and loud, a refusal rather than a reading, and
# nothing is silently cleared by it. A matcher that accepts too much is how f5fac73's defect
# got in: `printf '%s\n' "$OUT" | sed 's/^/           > /'` re-emits [FAIL] lines from a
# CAPTURED output, so a `printf`-tolerant matcher would let a fire-proof's own evidence dump
# stand in for the assertion reporting — the same class as the `grep -q 'A1 snapshot probe'`
# satisfier, reintroduced. If this is ever widened, it needs fire-proofs in BOTH directions:
# a `printf` verdict accepted, and a `printf` evidence dump still refused.
REPORT_ECHO = re.compile(r"^[ \t]*echo[ \t]+\"[ \t]*\[(?:ok|FAIL|WARN|note)\][ \t]*")


def call_sites(fn):
    pat = re.compile(CALL_PRE + re.escape(fn) + CALL_POST)
    dfn = re.compile(r"^[ \t]*" + re.escape(fn) + r"\(\)")
    out = []
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith("#") or dfn.match(ln):
            continue
        out.extend(i + 1 for _ in pat.finditer(ln))
    return out


KINDS = ("INVOCATION", "BLOCK", "EXTERNAL")
kindcount = {k: 0 for k in KINDS}
blockdist = []
for name in sorted(defined):
    if name not in rows:
        continue
    label, claims, note, lineno = rows[name]
    kv = {}
    malformed = []
    for tok in claims.split():
        if tok.count("=") != 1 or not tok.split("=")[1]:
            malformed.append(tok)
        else:
            k, v = tok.split("=")
            kv[k] = v
    if malformed or set(kv) != {"kind", "callers"}:
        print("  [FAIL] %s:%d claims column is %r; it must be exactly `kind=<K> callers=<N>`"
              % (path, lineno, claims))
        bad = 1
        continue
    kind = kv["kind"]
    if kind not in KINDS:
        print("  [FAIL] %s:%d declares kind=%s for %s(); the kinds are %s"
              % (path, lineno, kind, name, "/".join(KINDS)))
        bad = 1
        continue

    sites = call_sites(name)
    if not kv["callers"].isdigit():
        print("  [FAIL] %s:%d callers=%s is not a number" % (path, lineno, kv["callers"]))
        bad = 1
    elif int(kv["callers"]) != len(sites):
        print("  [FAIL] %s:%d says %s() has callers=%s; the rule in this table's header"
              " counts %d" % (path, lineno, name, kv["callers"], len(sites)))
        print("         Call sites: %s" % ", ".join("%s:%d" % (src, s) for s in sites[:8])
              + (" ..." if len(sites) > 8 else ""))
        print("         A note claiming a count nobody reads is caveat (4); this column is")
        print("         the part of it that a machine can hold true.")
        bad = 1

    inv = re.compile(r"^[ \t]*" + re.escape(name) + r"[ \t]+\"" + re.escape(label) + r"\"")
    inv_at = [i + 1 for i, ln in enumerate(lines) if inv.match(ln)]

    if kind == "EXTERNAL":
        if label != "NOT-PROVEN-IN-HARNESS":
            print("  [FAIL] %s:%d declares kind=EXTERNAL for %s() but names an in-harness"
                  " label %r" % (path, lineno, name, label))
            bad = 1
    elif label == "NOT-PROVEN-IN-HARNESS":
        print("  [FAIL] %s:%d says %s() is NOT-PROVEN-IN-HARNESS but declares kind=%s"
              % (path, lineno, name, kind))
        print("         An unprovable instrument is kind=EXTERNAL; anything else claims a")
        print("         proof this harness does not contain.")
        bad = 1
    elif kind == "INVOCATION":
        if not inv_at:
            print("  [FAIL] %s:%d declares kind=INVOCATION for %s(), but no line of %s calls"
                  " it with that label as its first quoted argument"
                  % (path, lineno, name, src))
            print("         Label: %s" % label)
            print("         This is the scratch_appendonly defect (b4442cf): a row naming a")
            print("         real assertion that never calls the function it declares.")
            bad = 1
    else:  # BLOCK
        if inv_at:
            print("  [FAIL] %s:%d declares kind=BLOCK for %s(), but the INVOCATION form holds"
                  " at %s:%d" % (path, lineno, name, src, inv_at[0]))
            print("         The strongest satisfied kind must be declared, or the column is")
            print("         an opt-out from the check it exists to impose.")
            bad = 1
        else:
            hit = None
            bare = None
            for i, ln in enumerate(lines):
                if label not in ln:
                    continue
                near = [s for s in sites if 0 < (i + 1) - s <= BLOCK_WINDOW]
                if not near:
                    continue
                m = REPORT_ECHO.match(ln)
                if m and ln[m.end():].startswith(label):
                    hit = (i + 1, max(near))
                    break
                if bare is None:
                    bare = (i + 1, max(near))
            if hit is None:
                print("  [FAIL] %s:%d declares kind=BLOCK for %s(), but no [ok]/[FAIL] REPORT"
                      " line naming its label sits within %d lines below a call site"
                      % (path, lineno, name, BLOCK_WINDOW))
                print("         Label: %s" % label)
                if bare is None:
                    print("         WHY: the label does not occur in %s below a call site at"
                          " all." % src)
                else:
                    print("         WHY: an occurrence IS in window, at %s:%d (+%d), and it is"
                          " not a report line:" % (src, bare[0], bare[0] - bare[1]))
                    print("           %s" % lines[bare[0] - 1].strip()[:100])
                    print("         Until 2026-08-02 that occurrence satisfied this check. In")
                    print("         the live harness the satisfier was `grep -q 'A1 snapshot")
                    print("         probe'` — the text the assertion searches FOR — so the row")
                    print("         was proven by a string the harness never prints. A kind of")
                    print("         BLOCK claims the assertion REPORTS under this label.")
                bad = 1
            else:
                blockdist.append((name, hit[0] - hit[1]))
    kindcount[kind] += 1

# --- LEG 4 (ITEM N4, round 10 drain-2, 2026-08-02): A COPY MAY NOT BE WRITTEN WITHOUT A
# CONFIRMATION OF WHAT WENT INTO IT.
#
# WHAT IT CLOSES. LEG 2 above checks that every copy-confirmation GUARD is anchored, and its
# caveat (vi) says outright that the number it prints is a FLOOR: delete one of the two
# guards and LEG 2 still prints [ok] with a smaller number. Round 8 looked for a derived
# invariant to pin it against and did not find one, because the `$..._COPY` VARIABLES are not
# in bijection with the guards — several legs confirm in python instead. Round 9 measured the
# thing that IS in bijection: copy BUILDERS. Every line that writes a copy has a confirmation
# of what went into it, in one of two forms, and that is a coverage rule rather than a count.
#
# THE TWO CONFIRMATION FORMS ARE THE TWO THE CORPUS ACTUALLY USES:
#   shell-redirect  `sed|grep … > "$_X_COPY"` followed within CONFIRM_WINDOW lines by an
#                   anchored `grep -q…"$_X_COPY"`. LEG 2 then checks that guard is anchored;
#                   this leg checks it EXISTS. The two halves are what make the pair sound.
#   python          `open(…'_X_COPY'…,'w')` with an `assert` earlier in the SAME python
#                   program. This is item A2's first form, applied inside the builder.
#
# THE BUILDER DEFINITION IS THREE SYNTAXES AND THAT IS NOT COSMETIC. Reconstructing it from
# caveat (vi)'s recorded COUNT — a HISTORICAL measurement over the round-9 corpus, quoted here
# as history and not as this file's population — the obvious two, a shell redirect plus
# `open('$_X_COPY','w')`, returned SIX of the ten then known, silently: a plausible number, no
# error, and a coverage rule proven against a population missing four members. The four
# invisible ones write through the environment,
# `open(os.environ['_X_COPY'],'w')`. The per-syntax census is PRINTED on every run for exactly
# that reason: a syntax dropping to zero is now visible, where the third one's absence was not.
#
# WHY IT IS NOT SATISFIED BY ITS OWN SOURCE (item A2, the standing hazard in this file). Two
# independent mechanisms, and BOTH are real here rather than one being decorative:
#   * the three builder patterns escape the metacharacter they search for — the source of
#     BUILD_PY_LIT contains `open\(`, and the pattern demands `open` followed by a literal
#     `(`, so no builder regex matches its own definition line (checked);
#   * the scan is bounded to the --selftest region, which excludes this gate body entirely.
# Unlike LEG 2, whose first mechanism alone would not save it (caveat (v) there contains a
# line the compiled pattern DOES match), neither mechanism here is currently load-bearing on
# its own. That is a weaker claim than LEG 2's standing proof, and it is stated as weaker:
# nothing would go RED if the escaping stopped working, because the region bound would still
# hold. The fire-proofs below are what hold this leg non-vacuous, not this paragraph.
#
# WHAT LEG 4 CANNOT SEE, stated because a clear is weaker than a failure:
#   (xii)  It resolves the extent of a python program by QUOTE PARITY, walking up from the
#          builder to the nearest line with an odd number of unescaped `"`. If that line ends
#          with `"` it opens a shell string and the program starts below it; if it does not,
#          the builder is not inside a string at all and this leg refuses rather than
#          guessing. NO POPULATION IS QUOTED HERE ON PURPOSE — the first draft of this
#          sentence said "all eight python builders", and the same commit that wrote it
#          added three more. Every python builder resolving is what a green run of this leg
#          MEANS, so the run is the statement and this comment is not. It is NOT a shell
#          parser: a `'` -quoted blob, a heredoc, or a `$'…'` string would break the parity
#          walk, and a builder inside one would be refused with a FAIL naming the line —
#          conservative, but a FAIL nonetheless.
#          THE PARITY WALK DELIBERATELY DOES NOT SKIP COMMENT LINES, and that is the
#          opposite of what `uncommented` does two paragraphs up, so the reason is worth
#          having in writing before someone "fixes" it: inside the blob these lines are
#          PYTHON comments, the shell sees the whole blob as one quoted string, and their
#          quotes therefore do count toward its parity. Skipping them would desynchronise
#          the walk from what the shell actually did. Above the blob a shell comment's
#          quotes do NOT count — but the walk stops at the blob opener before it can reach
#          one, so the distinction never arises in the direction that would be wrong.
#   (xiii) It checks that an `assert` EXISTS earlier in the program, not that the assert is
#          ABOUT the thing being written. `assert 1==1` would satisfy it. This is the same
#          class as caveat (viii)'s proximity-not-reachability, one level down, and it is why
#          the shell half cross-checks against LEG 2's extractor and the python half does not:
#          no second extractor exists for the python form.
#          STILL NOT BUILT, AND THE OBVIOUS BUILD WAS MEASURED AND REJECTED (item R5, round 11
#          drain-1, 2026-08-02). The natural second extractor is a taint rule: the assert must
#          reference a name derived from the READ of the file being mutated. Evaluated against
#          every live python builder, it FAILS on the counter-shaped ones — the builders that
#          bind `n = 0`, increment it inside a loop over the file's lines, and then
#          `assert n > 0`. Their assert IS about the file, by a route the rule cannot see:
#          the increment rides on a `;`-joined statement or an element assignment (`L[i] = …`),
#          neither of which is a plain binding. A refinement that tainted loop-body bindings
#          was measured too and failed the same two for the same reason. SHIPPING IT WOULD
#          HAVE TURNED A CLEAN CORPUS RED, which is the failure R4's measurement caught one
#          leg over on the same day, so the epicycles stop here and the limit is recorded
#          instead.
#          THE WEAK FORM IS ALSO DECLINED, on this file's own threshold rather than on taste.
#          Requiring only that the assert mention some identifier would kill `assert 1==1` and
#          nothing else, and it passes every live builder — but LEG 2's header sets four
#          sightings as the bar for converting care into a mechanism, and the vacuous-assert
#          defect has ZERO sightings here. Building for it would add a leg, a fire-proof and a
#          callers count against a hypothetical. What makes this a live risk is asymmetry, not
#          frequency: the shell half is cross-checked and the python half is not, and it is the
#          LARGER half. That is the argument for a real second extractor, and it is not an
#          argument for a cheap one.
#          DECIDED 2026-08-02 (item R5', round 12 drain-2) — DECLINED, and written down so the
#          next unit inherits a decision instead of the question. What is left to build is
#          `;`-statement splitting plus subscript-target recognition, and the ONLY thing those
#          two epicycles do is re-admit two builders already known to be correct. A rule
#          extended until it clears the corpus it was extended against carries no evidence
#          about the next shape it meets, and the construct with this project's highest
#          measured defect density is the CHECKER, not the fix. THE ASYMMETRY ARGUMENT ABOVE IS
#          NOT WITHDRAWN: the larger half is still the uncross-checked one, and it stays that
#          way until a second extractor derived from something other than this corpus exists.
#          What is declined is the cheap one, on the reasoning above rather than on cost.
#   (xiv)  It sees the WRITE, not the CONTENT. A builder that asserts correctly and then
#          writes different bytes is outside it.
BUILD_SH = re.compile(r">[ \t]*\"\$(_[A-Za-z0-9_]*COPY)\"")
BUILD_PY_LIT = re.compile(r"open\([ \t]*'\$(_[A-Za-z0-9_]*COPY)'[ \t]*,[ \t]*'w'")
BUILD_PY_ENV = re.compile(
    r"open\([ \t]*os\.environ\[[ \t]*'(_[A-Za-z0-9_]*COPY)'[ \t]*\][ \t]*,[ \t]*'w'")
UNESCAPED_DQ = re.compile(r'(?<!\\)"')
PY_ASSERT = re.compile(r"^[ \t]*assert[ \t]")
CONFIRM_WINDOW = 2

def uncommented(ln):
    # A COMMENT CANNOT WRITE A FILE, and leaving this out was not a hypothetical. This leg's
    # own header comment contains the prose `> "$_X_COPY"` describing what a builder looks
    # like, and the first run read it AS one and demanded a guard for it. Same shape as GATE
    # 16 LEG 2's `uncomment`, found the same way — by running, not by reading. The header
    # sentence is deliberately left as it stands: it is a live occurrence of the pattern, in
    # a comment, inside the scanned region, so if this skip is ever removed the leg goes RED
    # on its own documentation rather than quietly mis-reading someone else's.
    return "" if ln.lstrip().startswith("#") else ln


builders = []
for i in range(start + 1, end):
    for rx, style in ((BUILD_SH, "shell-redirect"), (BUILD_PY_LIT, "python-literal"),
                      (BUILD_PY_ENV, "python-environ")):
        m = rx.search(uncommented(lines[i]))
        if m:
            builders.append((i + 1, style, m.group(1)))

if not builders:
    print("  [FAIL] LEG 4: zero copy BUILDERS found in the --selftest region (lines %d-%d)."
          % (start + 1, end + 1))
    print("         They exist, in THREE syntaxes, and the third was invisible to the")
    print("         obvious definition of a builder — which is why this message states no")
    print("         expected number: the per-syntax census on the [ok] line is the live")
    print("         count and this text would only go stale beside it. Finding none means")
    print("         this extractor stopped reading them, not that the harness stopped")
    print("         building copies — a checker that finds nothing must never report [ok].")
    bad = 1

guard_lines = {g[0] for g in guards}
shdist, pyconf = [], 0
for lineno, style, var in builders:
    if style == "shell-redirect":
        hit = None
        for j in range(lineno, min(lineno + CONFIRM_WINDOW, end) + 1):
            cand = uncommented(lines[j - 1])
            if ("$" + var) in cand and re.search(r"grep[ \t]+-q", cand):
                hit = j
                break
        if hit is None:
            print("  [FAIL] LEG 4: %s:%d writes $%s and no anchored guard within %d line(s)"
                  " confirms what went into it." % (src, lineno, var, CONFIRM_WINDOW))
            print("           %s" % lines[lineno - 1].strip())
            print("         `sed`/`grep` build the copy FROM this file, so a moved anchor")
            print("         yields a byte-identical copy and every assertion downstream")
            print("         passes with the injection switched off. Confirm the injection")
            print("         with an anchored `grep -qE` before using the copy.")
            bad = 1
            continue
        if hit not in guard_lines:
            print("  [FAIL] LEG 4: %s:%d confirms $%s at %s:%d, and LEG 2 did not extract"
                  " that line as a guard." % (src, lineno, var, src, hit))
            print("           %s" % lines[hit - 1].strip())
            print("         Two extractors written for different purposes disagree, so one")
            print("         of them is wrong. If LEG 2's is, it is silently checking fewer")
            print("         guards than the harness has and still printing [ok] — which is")
            print("         the count-nobody-reads failure this leg exists to end.")
            bad = 1
            continue
        shdist.append((var, hit - lineno))
    else:
        opener = None
        for k in range(lineno - 1, start + 1, -1):
            if len(UNESCAPED_DQ.findall(lines[k - 1])) % 2 == 1:
                opener = k if lines[k - 1].rstrip().endswith('"') else None
                break
        if opener is None:
            print("  [FAIL] LEG 4: %s:%d writes $%s and this leg could not establish which"
                  " python program it belongs to." % (src, lineno, var))
            print("         The parity walk found no line opening a shell string above it")
            print("         (caveat xii). A builder whose program cannot be delimited is")
            print("         refused, not cleared: the alternative is reading an unrelated")
            print("         `assert` from the program above as this one's confirmation.")
            bad = 1
            continue
        if not any(PY_ASSERT.match(lines[k - 1]) for k in range(opener + 1, lineno)):
            print("  [FAIL] LEG 4: %s:%d writes $%s with no assert earlier in the same"
                  " python program (opens at %s:%d)." % (src, lineno, var, src, opener))
            print("           %s" % lines[lineno - 1].strip())
            print("         The builder reads THIS file and writes a mutated copy of it. An")
            print("         anchor that has moved then produces a copy with nothing injected,")
            print("         and every assertion using it passes for the wrong reason. Assert")
            print("         the anchor count before the write, as the other builders do.")
            bad = 1
            continue
        pyconf += 1

if not bad:
    unprov = sum(1 for n in defined if rows[n][0] == "NOT-PROVEN-IN-HARNESS")
    # WORDED DOWN 2026-08-02 (round 8, item A3). This read "%d proven by a named assertion",
    # which is the over-claim caveat (1) of the table exists to deny — and the audit that
    # round found one of these rows naming a real assertion that never calls its function
    # (scratch_appendonly, misdeclared since GATE 15 shipped at 6d93ed5). A gate whose own
    # pass line claims more than its check performs is the false attestation this suite is
    # for, so it now says what it did: the label was found.
    print("  [ok] %d instrument(s) in the --selftest region, all declared; %d name an"
          " assertion whose label EXISTS (caveat 1: existing is not exercising),"
          " %d declared unprovable in-harness"
          % (len(defined), len(defined) - unprov, unprov))
    print("  [ok] %d copy-confirmation guard(s) all anchored at line start, so none can be"
          " satisfied by the fire-proof's own source text (item A2)" % len(guards))
    print("  [ok] claims column: %d kind=INVOCATION (label IS the call's first argument),"
          " %d kind=BLOCK, %d kind=EXTERNAL; every callers=N matches the header's rule"
          % (kindcount["INVOCATION"], kindcount["BLOCK"], kindcount["EXTERNAL"]))
    print("  [ok] BLOCK: each row's [ok]/[FAIL] REPORT line measured below a call site, not"
          " assumed (window %d): %s — caveat (viii): a report line is still proximity, not"
          " reachability"
          % (BLOCK_WINDOW, ", ".join("%s +%d" % b for b in sorted(blockdist))))
    syn = {}
    for _b in builders:
        syn[_b[1]] = syn.get(_b[1], 0) + 1
    print("  [ok] LEG 4: %d copy builder(s), every one confirmed — %d by an anchored guard"
          " LEG 2 also extracted (distance %s), %d by an assert earlier in the same python"
          " program" % (len(builders), len(shdist),
                        ", ".join("%s +%d" % d for d in sorted(shdist)), pyconf))
    print("       builder syntaxes seen: %s — a syntax falling to zero is a rewrite this"
          " leg can no longer see, not a corpus that stopped building copies"
          % ", ".join("%s %d" % (k, syn[k]) for k in sorted(syn)))
sys.exit(bad)
PY
}

# ----------------------------------------------------------------------------------
# GATE 16 — no per-gate assertion may be satisfiable by a PREFLIGHT (ITEM A2, 2026-08-02).
#
# WHY THIS EXISTS. Item A6 nearly shipped one: a new preflight would have printed the exact
# string GATE 11's fire-proof asserts on, so the preflight — which runs before EVERY mode —
# would have satisfied an assertion written about GATE 11, and GATE 11's leg could have
# stopped working without any assertion noticing. It was caught by hand. That is the A3/A7
# shared-DISPATCH defect arriving through a shared MESSAGE, and require_final_newline's
# `quiet` argument exists solely to dodge it. The dodge is real; the CHECK on the dodge was
# a sentence in a comment ("The preflight's wording therefore shares no substring with this
# one") that had never been mechanically verified. This gate verifies it.
#
# WHAT IT DOES. Extracts the evidence-ERE from every assert_fires_why invocation, extracts
# every line the two preflights can emit, expands their `$f` over the real file lists, and
# fails if any ERE matches any preflight-emittable line. Two preflights now run before every
# mode and both emit [FAIL] lines, so this is not hypothetical arithmetic.
#
# THE EXEMPTION IS NAMED AND PRINTED, NEVER SILENT. Two assertions are ABOUT a preflight and
# must match its output — that is their whole purpose. They are identified by their LABEL
# containing "preflight" (case-insensitive) and are listed in the output every run, so the
# exemption cannot quietly grow to cover an assertion that should have failed.
#
# THE VACUITY GUARDS, because the failure mode of this gate is finding nothing and saying
# [ok] — the same shape as the checker whose false clear hid a Lean defect for twelve hours
# on 2026-08-01. NAMED RATHER THAN COUNTED (round 15 drain-2): this header said "THREE
# VACUITY GUARDS" and a fourth was being added under it, which is the R14/R16 shape — a bare
# multiplicity in a comment that no reader can check against the code. A named list can be
# checked; a number cannot, and this file has now rotted four of them.
#   (1) one ERE must be extracted per assert_fires_why invocation; a mismatch is a FAIL, so
#       a parser that silently skips a call cannot pass;
#   (2) the preflight message set must be non-empty, per preflight and in total;
#   (3) the expanded candidate-line set must be non-empty;
#   (4) THE EMITTER POPULATION ITSELF IS DERIVED FROM THE DISPATCH, not declared here. Guards
#       (1)-(3) all presume the right set of functions is being read; until round 15 that set
#       was a two-element tuple in the gate body, and round 14 had already shipped a third
#       pre-dispatch emitter past it — see (c2) below. Both directions FAIL: a top-level call
#       this gate neither scans nor exempts, and a name it declares that the dispatch no
#       longer calls.
#   (5) THE POPULATION ONE LEVEL DOWN. Guard (4) proves which functions the DISPATCH calls;
#       it does not follow a call, and neither does body(). Round 15's drain-2 filed that
#       limit against its own instrument and drain-3 measured it: preflight_support_newlines
#       calls require_final_newline, whose non-quiet branch prints the EXACT evidence-ERE of
#       the checked assertion "GATE 11 (figures) registry with no final newline drops its
#       last row", and only the literal `quiet` at that one call site keeps it out of the
#       candidate set. Nothing read that call site. Guard (5) declares each nested callee
#       with the argument that suppresses it and MEASURES both halves — the call site passes
#       the literal, and the callee returns on it before its first echo — so the exemption
#       is re-taken on every run rather than re-argued. THREE of its directions are driven by
#       a self-test leg, one each: an undeclared callee; a declared one whose suppressing
#       argument has gone from the call site; a declared one the pre-dispatch bodies no
#       longer call. It has THREE FURTHER [FAIL] branches that no leg drives — an emptied
#       declaration, a callee whose body cannot be found, and a callee that stopped honouring
#       the literal while the call site still passes it. Both groups are NAMED rather than
#       counted, because the first draft of this paragraph said "three directions FAIL" over
#       six branches, which is the R14/R16 shape inside the sentence describing the fix. It
#       closes the population question ONE level; what it does not close is at its definition.
#   (6) THE READER ITSELF. body() serves guard (2)'s template scan AND guard (5), and it stops
#       at the first column-0 "}" — exact for a shell function, wrong inside a heredoc, where
#       that brace is quoted text. MEASURED: gate_preflight_collisions' own span carries three
#       such lines, two of them python dict terminators in its heredocs, so the shape exists in
#       this file and merely does not exist in any function body() is called on. Truncation is
#       SILENT for guard (5) and only half-loud for guard (2), which sees a preflight fall to
#       zero templates but not to fewer. One direction, one leg.
#   (7) THE INVOCATION POPULATION ITSELF. Added round 16 drain-1 (d50671f8): LEG 1's
#       collision scan read one helper (`assert_fires_why`) at one indentation, while LEG 2
#       of the same gate read both helpers by call position — so the two legs disagreed
#       about which invocations exist and the WEAKER rule was doing the collision scan.
#       Both halves are here: an invocation the scan cannot reach is a FAIL naming the
#       shortfall against `callers=`, not a smaller number. THIS ENTRY WAS MISSING (round
#       16 drain-2): d50671f8 added the guard, its fire-proofs and its own "WHAT GUARD (7)
#       CANNOT SEE" block, and did not extend the list above — so the list that exists
#       BECAUSE a named list can be checked was itself incomplete for one round.
#
# WHAT IT CANNOT SEE, stated rather than implied:
#   (a) `assert_stays_clean_why` and `assert_gen_*` are outside this scan. NARROWED TWICE on
#       2026-08-02. First (item A1, round 8): this note used to name assert_fires, and that
#       helper's six callers have since been converted to assert_fires_why — each with an
#       evidence-ERE taken from a real run — and the helper deleted, so those six are now
#       INSIDE this scan. Second (item A1's residue, drain-3): the note also said
#       assert_stays_clean "asserts on an EXIT CODE (rc 0) and carries no ERE", and that is
#       now FALSE — its six callers each carry an evidence-ERE too, and it was renamed
#       assert_stays_clean_why to say so at the call site.
#       IT IS STILL EXCLUDED, and now for a reasoned rather than a structural cause: a
#       preflight-emittable ERE cannot produce a false [ok] on a negative control, because
#       both preflights set RC=1 at their `|| RC=1` call sites below, so a firing preflight
#       fails that assertion at its rc test before the ERE is consulted. The collision this
#       gate exists to refuse is a FALSE PASS; on the stays-clean side the same collision can
#       only produce a loud [FAIL]. Extending the extractor to a second call shape would also
#       have to keep guard (1) exact, and guard (1) is what makes this gate non-vacuous.
#       RE-VERIFIED END TO END, round 15 drain-2, because round 15's inbox carried a filed
#       item asserting the OPPOSITE — that a collision here is a false clear. Every link was
#       read: both preflight bodies print only inside the branch that sets their `bad`/
#       `missing` flag and that branch `return 1`s, so PRINTING IMPLIES RETURN 1; both call
#       sites are `|| RC=1`; the script ends `exit $RC`; and assert_stays_clean_why tests
#       `[ "$rc" -ne 0 ]` and returns BEFORE its `grep -qE` on the ERE. The exclusion holds
#       and the direction in that item was backwards. What this re-verification does NOT
#       establish is anything about an emitter that prints WITHOUT setting RC — see (c2).
#       assert_gen_* remain outside for the older and weaker reason: they do assert on an
#       evidence-ERE, but against GATE 8's `generated` output rather than through this
#       extractor.
#   (b) It over-approximates the candidate files (both preflights' file lists are unioned),
#       which is the conservative direction: it can report a collision that a real run would
#       not produce, never miss one that it would.
#   (c) LEG 1 reasons about the preflights only. A collision between two PER-GATE messages is
#       a different question — and LEG 2 below now asks half of it.
#   (c2) THE PREFLIGHTS ARE NOT THE ONLY THING THAT RUNS BEFORE EVERY MODE, and this list did
#       not say so until round 15. `doc_gates_concurrency_advisory` (round 14's R15 item) is
#       called at top level between MODE= and the dispatch and prints seven lines. It is
#       EXEMPT, and for a cause unlike (a)'s: it is not that a collision there would be loud,
#       it is that it cannot happen at all — the function returns before its first echo
#       whenever DOC_GATES_SELFTEST_DEPTH is set, the --selftest branch exports that marker,
#       and every assertion in this file greps a run that descends from it. NOTE THE SHAPE OF
#       THE DIFFERENCE: (a)'s argument is about RC, and the advisory deliberately does NOT
#       touch RC, so (a)'s reasoning would not have covered it. It shipped outside this scan
#       for a whole round with nothing to say so; guard (4) is why the next one cannot.
#       The exemption's evidence is the self-test leg labelled "R15 concurrency advisory",
#       which drives the independent direction with `env -u DOC_GATES_SELFTEST_DEPTH`. Delete
#       that leg and this exemption has no evidence left — re-take it, do not re-argue it.
#
# LEG 2 — NO FIRE-PROOF MAY NAME A DISPATCH THAT RUNS MORE THAN ONE GATE (item B2, round 9,
# 2026-08-02).
#
# WHY IT IS A MECHANISM AND NOT MORE CARE. This is the same defect as LEG 1 reached from the
# other side: an assertion satisfiable by something other than the gate it names. LEG 1's
# "something" is a preflight; LEG 2's is the OTHER gate behind a shared dispatch name. It has
# now been found and fixed BY HAND six times — GATE 10a, GATE 10b, GATE 4b, GATE 11-figures
# (round 8), GATE 11-phrases (round 9, and that one was LIVE: both halves of GATE 11
# require_tracked the same ledger, so the assertion stayed green with the guard it tested
# deleted), and GATE 4 (this batch). Four sightings is this project's stated threshold for
# converting care into a mechanism; this is the sixth.
#
# WHAT IT DOES. Resolves each `assert_fires_why` / `assert_stays_clean_why` invocation's
# dispatch name through the `case` block and the gate-to-gate call graph, and FAILS if it
# reaches more than one gate function, or a name the dispatch block does not define.
#
# IT SHIPS WITH NO EXEMPTION MECHANISM, AND THAT IS A MEASUREMENT, NOT AN OMISSION. B2
# specified an escape hatch — allow a combined name when the ERE is proven to come from
# exactly one of the gates behind it — because one assertion needed it. That assertion was
# GATE 4's, its wording argument was true, and it was retired anyway (see its DISPATCH NOTE),
# leaving a population of ZERO. A blanket refusal with nothing to allowlist is strictly
# stronger than a rule with one hand-argued row in it, so the escape hatch was not built. If
# a future assertion genuinely must run a combined name, this leg has to grow one — and the
# right form is then a declared reason in the source, not a silent pass.
#
# WHAT LEG 2 CANNOT SEE:
#   (d) `assert_gen_*` take no dispatch name at all (they drive the `generated` gate through
#       their own harness), so they are outside this scan entirely.
#   (e) It is a STATIC resolution of `case` arms and `gate_x || rc=1` call lines. A gate
#       reached by `eval`, by a variable, or from outside a gate function is invisible; so is
#       a leg SKIPPED at runtime inside a single gate function, which is a different failure
#       (LEG 2 says "one gate answered", never "the leg inside it ran").
#   (f) Its own two vacuity guards are what make a green here mean anything, and they are
#       cross-checks rather than proofs: the invocation count must equal the `callers=N` that
#       GATE 15 LEG 3 derives by a different rule, and at least one gate function must still
#       be seen calling two others. Both are fire-proven in the self-test.
#
# LEG 3 — A FIRE-PROOF'S EXPECTED SUBSTRING MUST NAME EXACTLY ONE MESSAGE TEMPLATE (item R4,
# round 11, 2026-08-02).
#
# WHY IT IS A MECHANISM AND NOT MORE CARE. LEGS 1 and 2 both refuse an assertion satisfiable
# by something other than the gate it names — a preflight, or the other gate behind a shared
# dispatch. LEG 3 is the third source of the same false pass and the one nearest the
# assertion: a DIFFERENT FINDING BY THE SAME GATE. A fire-proof driver greps its gate's output
# for a fixed string; if two of that gate's messages can print that string, the leg goes green
# on the wrong one and the injected defect was never observed. Until this leg, that was an
# ARGUMENT WRITTEN IN A COMMENT, stated separately in each driver's row in
# documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt, one of them ending "which is an argument,
# not a check". Item N2 is the same hazard from the maintenance side: a note naming a string
# no assertion asserts on. This leg makes both mechanical.
#
# WHAT IT DOES. Reconstructs every message this harness can print — python `print(...)`,
# joining the literals of one call, and shell `echo "..."` — then resolves each fire-proof's
# expected substring against that set and FAILS unless exactly one template can produce it.
#
# BOTH FORMS THE HARNESS USES, and the second was added because the first was not the whole
# population (round 11 drain-2, 2026-08-02, from the round-11 could-not-see column):
#   * the DRIVER form, a helper asserting on its positional `$2`; and
#   * the VARIABLE-CARRIED form, where the substring is selected away from the call site — in
#     GATE 15 LEG 2's pair, in a `case` arm — and the assertion greps for the variable.
# The second was outside this leg in BOTH directions on the day the leg shipped: not a driver
# positional, so never parsed, and not matched by the driver guard either, so not reported as
# an orphan. That is the state a vacuity guard exists to make impossible, so the sort over
# fixed-string assertions is now exhaustive: driver positional, named variable, or FAIL.
#
# THE MATCH IS NORMALISED, AND THE NORMALISATION IS THE WHOLE DESIGN. A driver substring is
# compared against the message AFTER substitution, so a substring that pins a formatted value
# cannot match the template literally. Every %-specifier in a template, and every digit run on
# BOTH sides, collapses to one wildcard — which is what lets `is 2 gates behind one exit code`
# resolve against `which is %d gates behind one exit code:`. This was measured before it was
# written: under a plain literal containment test that substring resolved to ZERO templates,
# and a leg shipped on that test would have gone RED on a corpus with no defect in it.
#
# WHAT LEG 3 CANNOT SEE, stated because a clear is weaker than a failure:
#   (g) ONE TEMPLATE IS NOT ONE INSTANTIATION. The leg proves the substring identifies one
#       message; it cannot prove it identifies one CALL of that message. Measured, and printed
#       on the [ok] line every run so it is not only here: two `_g16b` legs assert on the same
#       `is %d gates behind one exit code` wording, so either could be satisfied by any
#       assertion whose dispatch reaches that many gates. Closing this needs the value pinned,
#       not the wording — which is a different check and is not claimed here.
#   (h) IT DOES NOT COVER THE INLINE-LITERAL FIRE-PROOFS — the ones that write the expected
#       string at the assertion itself rather than passing it to a driver or selecting it into
#       a variable. (This caveat opened as "the parameterised drivers ONLY"; the
#       variable-carried form was brought inside the leg the same day, and the sentence was
#       corrected rather than left to describe a coverage the leg had outgrown.) MEASURED
#       2026-08-02, the majority of those resolve to zero templates under this test because
#       their substrings pin a `%s` VALUE (a function name, a file name) rather than a digit.
#       That is not a defect in those fire-proofs — pinning the value is the STRONGER one —
#       and the naive widening is worse than incomplete: treating `%s` as "anything" makes
#       every substring producible by every `%s`-bearing template, so the exactly-one rule
#       becomes vacuous rather than strict. The count is deliberately not quoted; it moves
#       with the corpus and the property is what matters.
#   (i) It sees the TEMPLATE, not whether that template is reachable in the mode the driver
#       runs. This is caveat (viii)'s proximity-not-reachability limit again, one gate over.
#   (j) The python reconstruction counts parentheses including those inside string literals
#       and is bounded to TPL_SPAN lines. A template it mis-joins resolves its substring to
#       zero and FAILS by name — loud and wrong-way-round, never a silent clear.
#   (k) THE VARIABLE-CARRIED HALF RESOLVES A NAME, NOT A SCOPE. It gathers every literal
#       assignment to the asserted name anywhere in the file and requires each to resolve
#       uniquely; it has no notion of function scope, and no notion of WHICH `case` arm the
#       run that asserts actually takes. Both directions of that are refusals rather than
#       clears — a name reused in an unrelated function would put an extra literal under the
#       rule, and an assignment it cannot read as whole string literals is a FAIL instead of a
#       comparison against a fragment — but a refusal is still not a reading, and this is
#       caveat (i)'s reachability limit one level in.
#   (l) THE EXHAUSTIVE SORT IS EXHAUSTIVE OVER ONE SPELLING. It triggers on `grep -qF "$`; a
#       fixed-string assertion written `grep -F -q` or `-Fq` would carry a fire-proof
#       substring past the sort AND past the FAIL that exists to catch a form it cannot
#       classify. MEASURED 2026-08-02 rather than assumed: no such spelling occurs in this
#       file as a live assertion, and the only non-`-F` `grep -q… "$…"` lines are comments.
#       THE MEASUREMENT COMMAND DOES NOT COME BACK EMPTY, THOUGH, AND THIS CAVEAT IS WHY: the
#       line above that quotes the two forms in order to name them is itself a hit, and the
#       commit that recorded the empty measurement is the commit that created it. Read that
#       hit as prose and not as an assertion — and note what it is an instance of (item R3):
#       a sentence stating a property of the corpus joining the corpus it describes, which is
#       exactly the class this round kept re-filing, arriving here inside the record of a
#       measurement. Widening the detector
#       is the safe direction — it is a trigger, not a matcher — but it would have to widen
#       the two classifiers with it, and this is being recorded on ZERO sightings, which is
#       under the threshold this file applied to item R5 the same day.
#       Second, smaller: one variable asserted at two DIFFERENT sites is resolved once and
#       only its first site is named. The substring is still checked, so this costs a name in
#       a message, not a comparison.
gate_preflight_collisions() {
  local rc=0
  echo "== GATE 16: no per-gate assertion is satisfiable by a preflight =="
  python3 - <<'PY' || rc=1
import os, re, subprocess, sys

# The same read-only source seam GATE 15 uses, and for the same reason: the mutation this
# gate must be proven against edits an assertion inside THIS file, which bash is executing
# (task #77). Read-only, and announced below so it cannot quietly weaken a real run.
src = os.environ.get("DOC_GATES_SRC_OVERRIDE") or "scripts/doc_gates.sh"
if src != "scripts/doc_gates.sh":
    print("  [note] scanning OVERRIDE source %s (DOC_GATES_SRC_OVERRIDE), not the live script"
          % src)
if not os.path.isfile(src):
    print("  [FAIL] %s is not a readable file, so zero assertions were compared" % src)
    sys.exit(1)
lines = (open(src, encoding="utf-8").read() if src != "scripts/doc_gates.sh" else subprocess.run(["bash", "scripts/doc_gates.d/logical_source.sh"], stdout=subprocess.PIPE, check=True).stdout.decode("utf-8")).splitlines()

# --- the assertions. The ERE is the first single-quoted token in the invocation's ARGUMENT
# LIST: the call line after the double-quoted label, then continuation lines, stopping at the
# line that opens the python mutation (column 0, `"`).
#
# THE STOP CONDITION IS NOT TIDINESS. Without it the scan walks into the mutation body and
# takes a quoted PYTHON literal as the ERE. Measured, not reasoned: with the 'spans a hard
# wrap' ERE deleted, the earlier 3-line-lookahead version reported the mutation's
# 'documentation/GUIDE.md' as that assertion's evidence-ERE — an assertion with NO evidence
# argument was scored as having one, and it then collided with a preflight line, so the gate
# fired for a reason that had nothing to do with the deletion. Found by running the vacuity
# fire-proof, which is exactly what that fire-proof is for.
#
# The label is skipped by starting the search after its closing quote, so a label containing
# an apostrophe cannot be mistaken for the ERE.
#
# --- GUARD (7), round 16 drain-1: THE POPULATION ITSELF was one helper and one CALL SHAPE
# short, and both omissions ran in the FALSE-CLEAR direction. This line used to read:
#
#     calls = [i for i, ln in enumerate(lines) if ln.startswith("  assert_fires_why ")]
#
#   (i)  assert_stays_clean_why was outside it entirely. For a fire-proof a preflight
#        collision still leaves the leg having RUN; for a negative control the evidence-ERE
#        is the ONLY thing separating an exemption that ran from a leg that never looked, so
#        an unscanned collision there is the stronger of the two hazards, not the weaker.
#   (ii) any invocation not at EXACTLY two leading spaces. That is not hypothetical in this
#        file: `_asc_probe=$(assert_stays_clean_why ...)` is live above, which is why the
#        declared totals exceed a two-space prefix grep by one on the stays_clean helper.
#        NO PAIR OF NUMBERS IS WRITTEN HERE ANY MORE (2026-08-11). This sentence read "the
#        declared totals are 62 and 9 while a two-space prefix grep returns 62 and 8", and
#        GATE 25's fire-proof pair moved every one of the four in a single commit — the
#        caveat-4 shape, in the guard whose whole subject is a population count that rotted.
#        The live totals are the `population assert_fires_why=N, assert_stays_clean_why=N`
#        printed by this leg's own [ok] line, cross-checked against callers=N; the DELTA is
#        the property, and it is exactly one, contributed by the `_asc_probe` call above.
#
# LEG 2 OF THIS SAME GATE ALREADY READ BOTH, by a call-position rule, and already
# cross-checked its per-helper totals against callers=N. So one gate's two legs disagreed
# about which invocations exist and the WEAKER rule was the one doing the collision scan.
# This guard adopts LEG 2's rule rather than inventing a third.
#
# THE CHECK THIS REPLACES WAS STRUCTURALLY DEAD. `len(found) != len(calls)` compared a list
# built by appending exactly once per element of `calls` against `calls` — False on every
# possible input. The sentence printed beneath it ("a parser that silently skips a call")
# described a guard that was not there, and neither omission above could have tripped it.
# The population is now cross-checked against callers=N, derived by a DIFFERENT rule over
# the whole file (GATE 15 LEG 3's), which is what makes disagreement possible at all.
#
# WHAT GUARD (7) CANNOT SEE — stated here, not left to the reader:
#   * A stays_clean COLLISION IS REPORTED, BUT IT IS NOT THE SAME HAZARD TODAY, and saying
#     otherwise would overstate what this scan buys. MEASURED 2026-08-03: both SCANNED
#     preflights echo only inside their failure branch and `return 1` from it, and both call
#     sites are `... || RC=1` — so a preflight that printed has already made the run's rc
#     non-zero, and assert_stays_clean_why fails on rc BEFORE it consults the ERE. The third
#     pre-dispatch emitter is suppressed in every --selftest descendant (EXEMPT_EMITTERS).
#     The stays_clean half is therefore a tripwire over a hazard currently blocked by two
#     independent structural facts — both of which are properties of the PREFLIGHTS, and
#     neither of which is re-read from this side. That is why it is scanned, and it is not a
#     claim that a collision is live.
#   * IT READS CALL SITES, NOT REACHABILITY — guard (4)'s limit, inherited unchanged.
HELPERS = ("assert_fires_why", "assert_stays_clean_why")
TABLE = "documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt"
# Deliberately character-identical to LEG 2's CALLPOS: two rules that are required to agree
# must not be two different regexes, or their disagreement becomes a third defect.
CALLPOS = re.compile(r"(?:^|\$\()\s*(?:[A-Za-z_][A-Za-z0-9_]*=\$\(\s*)?(%s)\s+(?!\()"
                     % "|".join(HELPERS))
QUOTED = re.compile(r"'((?:[^'\\]|\\.)*)'")
LABEL_ARG = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*(.*)$')
calls, found = [], []
for i, ln in enumerate(lines):
    if ln.lstrip().startswith("#"):
        continue                    # a comment cannot call anything (LEG 2's `uncomment`)
    m = CALLPOS.search(ln)
    if not m:
        continue
    helper = m.group(1)
    calls.append(helper)
    toks, j = [], i
    while j < len(lines):
        l = lines[j]
        if j > i and l.startswith('"'):
            break                   # the mutation body begins; the argument list is over
        toks.append(l)
        if not l.rstrip().endswith("\\"):
            break                   # the invocation ended here
        j += 1
    blob = " ".join(t.rstrip("\\").strip() for t in toks)
    tail = blob[blob.index(helper) + len(helper):].strip()
    la = LABEL_ARG.match(tail)
    label = la.group(1) if la else "<unparsed label at %s:%d>" % (src, i + 1)
    q = QUOTED.search(la.group(2)) if la else None
    found.append((label, q.group(1) if q else None, i + 1))

bad = 0
missing = [(l, n) for l, e, n in found if e is None]
for label, n in missing:
    print("  [FAIL] no evidence-ERE could be extracted from the assertion at %s:%d"
          " (%s)" % (src, n, label))
    print("         The extractor must produce exactly one ERE per invocation. An assertion")
    print("         scored as having evidence it does not have is the false-clear shape")
    print("         this gate exists to refuse.")
    bad = 1

# GUARD (7)'s vacuity half. A call this scan never REACHED is not reported as clean — it is
# not reported at all, and the [ok] line below would still print a plausible smaller number.
declared = {}
if os.path.isfile(TABLE):
    for ln in open(TABLE, encoding="utf-8").read().splitlines():
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        f = ln.split("\t")
        if len(f) >= 3:
            mm = re.search(r"callers=(\d+)", f[2])
            if mm:
                declared[f[0]] = int(mm.group(1))
else:
    print("  [FAIL] the collision scan's population has no second opinion: %s is missing, so"
          " an invocation it never reached would be invisible here" % TABLE)
    bad = 1
for h in HELPERS:
    mine = calls.count(h)
    if declared and h not in declared:
        print("  [FAIL] the collision scan found no callers=N for %s in %s, so a skipped"
              " invocation of it would leave that assertion uncompared forever" % (h, TABLE))
        bad = 1
    elif h in declared and declared[h] != mine:
        print("  [FAIL] the collision scan reached %d invocation(s) of %s; %s declares"
              " callers=%d" % (mine, h, TABLE, declared[h]))
        print("         The difference is not a rounding of the census — it is that many")
        print("         assertions whose evidence-ERE was never compared against anything.")
        bad = 1

# --- what the preflights can print.
def body(name):
    out, on = [], False
    for ln in lines:
        if ln.startswith(name + "() {"):
            on = True
            continue
        if on and ln == "}":
            break
        if on:
            out.append(ln)
    return out

# --- GUARD (4), round 15 drain-2: WHICH EMITTERS ARE IN SCOPE IS ITSELF A CENSUS, and it
# was a hardcoded two-element tuple on this line until now. Nothing re-derived it, so a THIRD
# function that runs before every mode could ship — and one already had. Round 14's R15
# advisory (doc_gates_concurrency_advisory) is called at top level between MODE= and the
# dispatch, prints seven lines, and was never added here or named in the gate's own
# "WHAT IT CANNOT SEE" list. It is exempt for a real reason, recorded below; the point is that
# nothing checked, and the next one would be exempt by accident.
#
# NAMED, NOT COUNTED. Every emitter is printed with its disposition, because a bare
# multiplicity is not checkable by a reader against reality and a named list is (O-census).
SCANNED = ("preflight_tracked_docs", "preflight_support_newlines")
EXEMPT_EMITTERS = {
    # MEASURED, not argued: this function's first statement returns before any echo when
    # DOC_GATES_SELFTEST_DEPTH is set; the --selftest branch exports it; every assertion in
    # this file captures a run that descends from that branch. So no assertion's captured
    # output can contain a line of its. Both directions of the suppression are re-proven on
    # every self-test by the leg labelled "R15 concurrency advisory", which drives the
    # independent direction with `env -u DOC_GATES_SELFTEST_DEPTH`. If that leg is ever
    # deleted, this exemption loses its evidence and must be re-taken, not re-argued.
    "doc_gates_concurrency_advisory":
        "suppressed in every --selftest descendant (DOC_GATES_SELFTEST_DEPTH), so it cannot"
        " print into any assertion's captured run",
}
_a = [i for i, ln in enumerate(lines) if ln.startswith('MODE="${1:-all}"')]
_b = [i for i, ln in enumerate(lines) if ln.startswith('case "$MODE" in')]
# A top-level call: a bare function name at column 0, optionally `|| RC=1`. Anchored at both
# ends, so an indented line inside the advisory's own body cannot be read as a call.
#
# WHAT GUARD (4) CANNOT SEE, stated here and not left to the reader (Phase-4, same pass):
#   * IT READS CALLS, NOT REACHABILITY. An emitter invoked from INSIDE one of these three
#     functions, or through a variable or `eval`, is invisible to this scan and would be
#     invisible to a green run. This guard closes the population question one level; it does
#     not close it.
#   * A TOP-LEVEL SHELL KEYWORD IN THIS REGION IS REPORTED AS AN UNKNOWN EMITTER. Write an
#     unindented `if ... fi` between MODE= and the dispatch and the bare `fi` matches this
#     pattern. That is deliberate and it is the LOUD direction: the region grew structure the
#     scan cannot read, and a [FAIL] saying so is better than a census quietly taken over a
#     shape it was not written for. No keyword blocklist, because a blocklist is a second
#     hand-maintained population and this guard exists because the first one rotted.
TOPCALL = re.compile(r"^([a-z_][a-z0-9_]*)(?:[ \t]*\|\|[ \t]*RC=1)?[ \t]*$")
emitters = []
if len(_a) != 1 or len(_b) != 1 or _b[0] <= _a[0]:
    print("  [FAIL] the pre-dispatch region of %s could not be located exactly once"
          " (MODE= x%d, dispatch x%d), so the emitter census was NOT taken"
          % (src, len(_a), len(_b)))
    print("         An empty census would print [ok] over zero emitters, which is the")
    print("         false-clear shape the OTHER vacuity guards of this gate exist for:")
    print("         (1),(2),(3),(5),(6),(7) — NAMED, not counted. This line said \"three")
    print("         other\" from the commit that added guard (4) (84b2a5ac), when three")
    print("         WAS the right number; guards (5),(6),(7) each falsified it without")
    print("         touching it. The `THE VACUITY GUARDS` header above this function was")
    print("         converted to a named list for that reason in that same commit, and")
    print("         no distance is quoted here because this PRINTED copy of a number is")
    print("         what the fix missed; a comment gate would never have seen it.")
    bad = 1
else:
    emitters = [(TOPCALL.match(lines[i]).group(1), i + 1)
                for i in range(_a[0], _b[0]) if TOPCALL.match(lines[i])]
    if not emitters:
        print("  [FAIL] zero top-level calls between MODE= and the dispatch in %s — the"
              " emitter census is inert, not clean" % src)
        bad = 1
    for _name, _n in emitters:
        if _name in SCANNED:
            print("  [note] pre-dispatch emitter %s() (%s:%d) — SCANNED below" % (_name, src, _n))
        elif _name in EXEMPT_EMITTERS:
            print("  [note] pre-dispatch emitter %s() (%s:%d) — EXEMPT: %s"
                  % (_name, src, _n, EXEMPT_EMITTERS[_name]))
        else:
            print("  [FAIL] %s:%d runs %s() before EVERY mode, and this gate neither scans"
                  " its messages nor exempts it" % (src, _n, _name))
            print("         A per-gate assertion satisfied by a line THAT function prints")
            print("         would pass with its own gate switched off — the A6 shape, one")
            print("         emitter over. Add it to SCANNED, or to EXEMPT_EMITTERS with the")
            print("         reason it cannot produce a false clear.")
            bad = 1
    _called = {_name for _name, _ in emitters}
    for _name in tuple(SCANNED) + tuple(EXEMPT_EMITTERS):
        if _name not in _called:
            print("  [FAIL] %s() is declared to this gate but is not called before the"
                  " dispatch in %s, so this census describes a run that no longer happens"
                  % (_name, src))
            bad = 1

# --- GUARD (5), round 15 drain-3: guard (4) proves which functions the DISPATCH calls. It
# does not follow a call, and neither does body() — so an emitter ONE LEVEL DOWN, invoked from
# inside a pre-dispatch function, is outside every guard above it. Filed as N3 by the unit
# that shipped guard (4), against its own instrument, which is the honest direction.
#
# THE MOTIVATING EXAMPLE IS LIVE, NAMED AND MEASURED, not synthesised.
# preflight_support_newlines calls require_final_newline, whose non-quiet branch prints
# "  [FAIL] $1 does not end with a newline". Expanded over documentation/RETRACTED_FIGURES.tsv
# that is EXACTLY the evidence-ERE of the CHECKED (non-exempt) assertion labelled "GATE 11
# (figures) registry with no final newline drops its last row". The only thing keeping that
# line out of this gate's candidate set is the literal `quiet` passed at that one call site —
# and until now NOTHING read that call site. Delete the word and GATE 11's fire-proof becomes
# satisfiable by a preflight line while this gate prints [ok]: the A6 shape, one level down.
# The comment above that fire-proof already argues the two wordings share no substring; that
# argument is true and it is not what holds, because it does not mention `quiet` at all.
#
# NAMED, NOT COUNTED, and the suppression is MEASURED rather than argued. For a callee
# declared here, this guard checks BOTH halves: that every pre-dispatch call site passes the
# suppressing literal, AND that the callee returns on that literal before its first echo. An
# exemption whose condition nothing re-reads is prose, and prose about a corpus property that
# nothing re-reads is the class this campaign has caught in eleven consecutive rounds.
NESTED = {
    "require_final_newline": ("quiet",
                              "its pre-dispatch caller passes the literal, and the callee"
                              " returns on it before its first echo, so none of its three"
                              " message lines can reach any run this gate compares against"),
}
_FUNCDEF = re.compile(r"^([a-z_][a-z0-9_]*)\(\) \{")
_defined = {m.group(1) for _ln in lines for m in [_FUNCDEF.match(_ln)] if m}
# A callee in COMMAND position. Comments are stripped first — a comment cannot call anything,
# and reading one as a call is exactly how LEG 2's first resolver hid the fan-out it was
# measuring (recorded at its own `uncomment`). The separator set is deliberately GENEROUS: a
# character class covers ; & && | || ( ) { } in one, so a pipeline or a backgrounded call is
# read, and the keyword list covers the compound forms. Over-reading costs a loud [FAIL] on a
# name this gate does not know; under-reading costs a silent clear, and this guard exists
# because a silent clear already happened one level up.
_NESTEDCALL = re.compile(r"(?:^|[;&|(){}]|\b(?:if|elif|then|else|do|while|until|not)\b|!)"
                         r"\s*([a-z_][a-z0-9_]*)\b")
#
# WHAT GUARD (5) CANNOT SEE, stated here and not left to the reader (Phase-4, same pass):
#   * ONE LEVEL, NOT TRANSITIVE. It does not follow the callee's own callees. MEASURED at the
#     time of writing: require_final_newline calls no function defined in this file, so the
#     third level is empty today — but nothing here would notice it filling.
#   * CALLS, NOT REACHABILITY — guard (4)'s limit inherited unchanged. A callee reached
#     through a variable or `eval` is invisible to this scan.
#   * THE SUPPRESSION CHECK IS TEXTUAL, NOT AN EVALUATION. It reads the call line for the
#     literal and the callee's body for an early return on it. A caller passing the literal
#     through a variable reads as UNSUPPRESSED (the loud direction, and the safe one); a
#     callee that printed from a helper before its early return would not be seen, which is
#     the quiet direction and is why the first bullet above matters.
#   * IT SCOPES TO THE PRE-DISPATCH BODIES. require_final_newline is also called from inside
#     GATE 11 (three sites, none of them quiet); those are a different question and LEG 1
#     does not ask it.
#   * THE CALL-SITE CHECK READS THE WHOLE LINE, so a trailing shell comment mentioning the
#     literal would satisfy it. Only a line whose FIRST character is `#` is dropped. Narrow,
#     stated rather than fixed: stripping trailing comments needs a lexer, because `#` also
#     occurs inside strings, and a wrong lexer is a worse instrument than a stated limit.
_nested = []
for _name, _ in emitters:
    for _bl in body(_name):
        if _bl.lstrip().startswith("#"):
            continue
        for _m in _NESTEDCALL.finditer(_bl):
            if _m.group(1) in _defined:
                _nested.append((_name, _m.group(1), _bl.strip()))
if not NESTED:
    print("  [FAIL] guard (5)'s nested-callee declaration is EMPTY. It was measured NON-empty"
          " when written (require_final_newline, from preflight_support_newlines), so an"
          " empty declaration means this guard was emptied, not that the hazard went away")
    bad = 1
for _caller, _callee, _site in _nested:
    if _callee not in NESTED:
        print("  [FAIL] %s() calls %s() one level down, and this gate neither scans its"
              " messages nor accounts for it" % (_caller, _callee))
        print("           call: %s" % _site)
        print("         A pre-dispatch function's callee prints before EVERY mode too, and")
        print("         body() does not follow a call — so its lines are outside guards (1)")
        print("         to (4). Suppress it on this path and declare it here with the")
        print("         argument that does the suppressing, or teach the scan to read it.")
        bad = 1
        continue
    _arg, _why = NESTED[_callee]
    if not re.search(r"\b%s\b.*\b%s\b" % (re.escape(_callee), re.escape(_arg)), _site):
        print("  [FAIL] %s() calls %s(), and the ONLY thing keeping that callee out of this"
              " gate's scan is the '%s' argument — which is not at this call site"
              % (_caller, _callee, _arg))
        print("           call: %s" % _site)
        print("         Its messages become preflight-emittable the moment this argument")
        print("         goes, and no guard above this one reads a callee at all.")
        bad = 1
        continue
    _cb = body(_callee)
    if not _cb:
        print("  [FAIL] %s() body not found in %s, so guard (5) could not check the '%s'"
              " suppression it rests on" % (_callee, src, _arg))
        bad = 1
        continue
    _echo_at = next((i for i, l in enumerate(_cb) if l.lstrip().startswith("echo ")), None)
    _sup_at = next((i for i, l in enumerate(_cb)
                    if ("= %s ]" % _arg) in l and "return" in l), None)
    if _echo_at is not None and (_sup_at is None or _sup_at > _echo_at):
        print("  [FAIL] %s() is called with '%s' from %s(), but its body no longer returns on"
              " '%s' before its first echo" % (_callee, _arg, _caller, _arg))
        print("         The call site still passes the argument and the callee no longer")
        print("         honours it, so this exemption's condition has gone false silently.")
        bad = 1
        continue
    print("  [note] nested pre-dispatch callee %s() <- %s() — SUPPRESSED: %s"
          % (_callee, _caller, _why))
_nested_seen = {c for _, c, _ in _nested}
for _callee in NESTED:
    if _callee not in _nested_seen:
        print("  [FAIL] %s() is declared to guard (5) but is not called from any pre-dispatch"
              " function in %s, so this declaration describes a run that no longer happens"
              % (_callee, src))
        bad = 1

# --- GUARD (6), round 15 drain-3: THE READER ITSELF. body() is the reader that guard (2)'s
# template scan and guard (5) both depend on, and it stops at the FIRST column-0 "}". For a
# shell function that rule is exact — a column-0 "}" closes the function — with one exception:
# inside a heredoc it is quoted text, not syntax.
#
# MEASURED IN THIS FILE, which is why this is a tripwire and not a hypothesis:
# gate_preflight_collisions' own span carries THREE column-0 "}" lines. Two are python dict
# terminators inside its heredocs (EXEMPT_EMITTERS and NESTED — the second one added by the
# pass that wrote this guard), and the third is its real close. So the triggering SHAPE exists
# here already; it simply does not exist in any function body() is called on. Give a preflight
# a heredoc tomorrow and body() truncates at the quoted brace.
#
# THE ASYMMETRY IS WHY THIS IS WORTH TEN LINES. A truncation is SILENT for guard (5) — every
# nested call past the cut disappears and the census prints [ok] over what is left. For guard
# (2) it is only half loud: that guard notices a preflight dropping to ZERO templates, not one
# dropping to fewer. A silent undercount in the reader would defeat both guards above it.
#
# WHAT GUARD (6) CANNOT SEE: the span it counts over runs to the NEXT function definition, not
# to the function's true end, so a bare column-0 "}" sitting in an intervening COMMENT block
# would be reported too. That is the loud direction and it is deliberate — the alternative is
# to find the true end by the same first-brace rule this guard exists to distrust.
_DEFLINE = re.compile(r"^[a-z_][a-z0-9_]*\(\) \{")
for _fn in sorted(set(SCANNED) | set(NESTED)):
    _start = next((i for i, l in enumerate(lines) if l.startswith(_fn + "() {")), None)
    if _start is None:
        continue        # the missing-body case is reported by body()'s own callers, not here
    _stop = next((i for i in range(_start + 1, len(lines)) if _DEFLINE.match(lines[i])),
                 len(lines))
    _closes = [i for i in range(_start + 1, _stop) if lines[i] == "}"]
    if len(_closes) != 1:
        print("  [FAIL] body() cannot be trusted on %s(): its span in %s carries %d column-0"
              " '}' line(s), not 1, and body() stops at the first"
              % (_fn, src, len(_closes)))
        print("         A column-0 '}' CLOSES a shell function, so a second one is quoted")
        print("         text — a heredoc. body() would truncate there, guard (5) would stop")
        print("         seeing calls past the cut with nothing to say so, and guard (2)")
        print("         only notices a preflight that goes to zero templates, not to fewer.")
        bad = 1

ECHO = re.compile(r'^\s*echo\s+"(.*)"\s*$')
templates = []
for fn in SCANNED:
    b = body(fn)
    if not b:
        print("  [FAIL] %s() body not found in %s, so zero preflight messages were compared"
              % (fn, src))
        bad = 1
    n_before = len(templates)
    for ln in b:
        m = ECHO.match(ln)
        if m:
            templates.append(m.group(1).replace('\\`', '`').replace('\\"', '"'))
    # PHASE-4: the global "no templates at all" guard below would not notice ONE preflight
    # going quiet — a rewrite from `echo` to `printf` in either function would drop its lines
    # from the comparison and leave the other's, and the count nobody reads would still look
    # plausible. Each preflight must contribute at least one line of its own.
    if b and len(templates) == n_before:
        print("  [FAIL] %s() contributed ZERO message templates, so none of its output was"
              " compared against any assertion" % fn)
        print("         The extractor reads `echo \"...\"` lines; if this preflight now")
        print("         emits its findings some other way, teach the extractor that way.")
        bad = 1

files = []
for glob in ("*.md", "documentation/DOC_GATE_*.txt", "documentation/*.tsv"):
    files += subprocess.run(["git", "ls-files", glob], capture_output=True, text=True
                            ).stdout.split()

if not templates:
    print("  [FAIL] zero preflight message templates extracted — the scan is inert, not clean")
    bad = 1
candidates = set()
for t in templates:
    if "$f" in t:
        for f in files:
            candidates.add(t.replace("$f", f))
    else:
        candidates.add(t)
if not candidates:
    print("  [FAIL] zero candidate preflight lines after expansion — the scan is inert")
    bad = 1

exempt, checked = [], 0
for label, ere, n in found:
    if ere is None:
        continue
    if "preflight" in label.lower():
        exempt.append((label, n))
        continue
    checked += 1
    try:
        rx = re.compile(ere)
    except re.error as exc:
        print("  [FAIL] %s:%d — the evidence-ERE of \"%s\" does not compile: %s"
              % (src, n, label, exc))
        bad = 1
        continue
    hit = next((c for c in sorted(candidates) if rx.search(c)), None)
    if hit is not None:
        print("  [FAIL] %s:%d — the assertion \"%s\" is satisfied by a PREFLIGHT line:"
              % (src, n, label))
        print("           ERE : %s" % ere)
        print("           line: %s" % hit.strip())
        print("         A preflight runs before EVERY mode, so this assertion would pass")
        print("         with the gate it names switched off entirely. Reword one of the two.")
        bad = 1

for label, n in exempt:
    print("  [note] EXEMPT (asserts ON a preflight, by design): %s (%s:%d)" % (label, src, n))

if not bad:
    # NAMED, NOT COUNTED (O-census): the per-helper population is printed because a bare
    # total cannot be checked by a reader against callers=N, and the whole reason this leg
    # was one helper short is that nobody could see which helpers it had reached.
    print("  [ok] %d evidence-ERE(s) checked against %d preflight-emittable line(s) from %d"
          " template(s); %d exempt; population %s"
          % (checked, len(candidates), len(templates), len(exempt),
             ", ".join("%s=%d" % (h, calls.count(h)) for h in HELPERS)))
sys.exit(bad)
PY
  echo "-- GATE 16 LEG 2: no fire-proof names a dispatch that runs more than one gate --"
  python3 - <<'PY' || rc=1
import os, re, subprocess, sys

# LEG 2 (item B2, round 9, 2026-08-02). See the gate header for why this is mechanical
# rather than another hand application.
src = os.environ.get("DOC_GATES_SRC_OVERRIDE") or "scripts/doc_gates.sh"
TABLE = "documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt"
if src != "scripts/doc_gates.sh":
    print("  [note] LEG 2 scanning OVERRIDE source %s, not the live script" % src)
if not os.path.isfile(src):
    print("  [FAIL] LEG 2: %s is not a readable file, so zero assertions were resolved" % src)
    sys.exit(1)
lines = (open(src, encoding="utf-8").read() if src != "scripts/doc_gates.sh" else subprocess.run(["bash", "scripts/doc_gates.d/logical_source.sh"], stdout=subprocess.PIPE, check=True).stdout.decode("utf-8")).splitlines()
bad = 0

def uncomment(ln):
    # A shell comment cannot call anything. Reading them as calls is how this unit's FIRST
    # resolver decided `secrefs` reached gate_links: gate_secrefs' body carries a comment
    # naming gate_links, and the collapsed graph then hid the very fan-out being measured.
    return "" if ln.lstrip().startswith("#") else ln

GATEDEF = re.compile(r"^(gate_[a-z0-9_]+)\(\) \{")
GATECALL = re.compile(r"(?:^|;|&&|\|\||\bthen\b|\belse\b|\bdo\b|\{|\()\s*(gate_[a-z0-9_]+)\b")
defined = {m.group(1) for l in lines for m in [GATEDEF.match(l)] if m}

def fnbody(name):
    out, on = [], False
    for ln in lines:
        if ln.startswith(name + "() {"):
            on = True
            continue
        if on and ln == "}":
            break
        if on:
            out.append(uncomment(ln))
    return out

direct = {f: sorted({g for ln in fnbody(f) for g in GATECALL.findall(ln)
                     if g != f and g in defined}) for f in sorted(defined)}

def leaves(f, seen=frozenset()):
    if f in seen:
        return set()
    kids = direct.get(f, [])
    if not kids:
        return {f}
    out = set()
    for k in kids:
        out |= leaves(k, seen | {f})
    return out

CASE_OPEN = 'case "$MODE" in'
CASE_CLOSE = "esac"
LABEL_ROW = re.compile(r"^\s{2}([a-z0-9|*-]+)\)\s*(.*)$")
try:
    a = next(i for i, l in enumerate(lines) if l.startswith(CASE_OPEN))
    b = next(i for i in range(a, len(lines)) if lines[i] == CASE_CLOSE)
except StopIteration:
    print("  [FAIL] LEG 2: the dispatch block was not found in %s, so every mode would"
          " resolve to nothing and this leg would be inert" % src)
    sys.exit(1)
disp, cur = {}, None
for i in range(a + 1, b):
    ln = lines[i]
    m = LABEL_ROW.match(ln)
    if m:
        cur = m.group(1)
        disp.setdefault(cur, [])
        rest = uncomment("  " + m.group(2))
    else:
        rest = uncomment(ln)
    if cur:
        disp[cur] += GATECALL.findall(rest)
    if cur and ";;" in ln:
        cur = None
disp.pop("*", None)
reach = {k: (set().union(*[leaves(f) for f in v]) if v else set()) for k, v in disp.items()}

# --- the fire-proofs and negative controls, and the dispatch name each one names.
HELPERS = ("assert_fires_why", "assert_stays_clean_why")
CALLPOS = re.compile(r"(?:^|\$\()\s*(?:[A-Za-z_][A-Za-z0-9_]*=\$\(\s*)?(%s)\s+(?!\()"
                     % "|".join(HELPERS))
LABEL_ARG = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*(.*)$')
found = []
for i, ln in enumerate(lines):
    if not uncomment(ln):
        continue
    m = CALLPOS.search(ln)
    if not m:
        continue
    helper = m.group(1)
    toks, j = [], i
    while j < len(lines):
        l = lines[j]
        if j > i and l.startswith('"'):
            break               # the python mutation body opens at column 0
        toks.append(l)
        if not l.rstrip().endswith("\\"):
            break
        j += 1
    blob = " ".join(t.rstrip("\\").strip() for t in toks)
    tail = blob[blob.index(helper) + len(helper):].strip()
    la = LABEL_ARG.match(tail)
    if not la:
        found.append((helper, "<unparsed label>", None, i + 1))
        continue
    gm = re.match(r"^([A-Za-z0-9_-]+)(?:\s|$)", la.group(2))
    found.append((helper, la.group(1), gm.group(1) if gm else None, i + 1))

# --- VACUITY GUARD 1: an INDEPENDENTLY-DERIVED count of the same call sites.
# The failure mode of this leg is an extractor that silently skips an invocation and still
# prints [ok] with a number nobody reads. GATE 15 LEG 3 already machine-checks a `callers=N`
# for each helper, derived by a DIFFERENT rule (command position over the whole file, round 9
# item B3's residue). Two extractors written for different purposes must agree, or one of
# them is wrong and this leg says so instead of reporting a smaller total.
declared = {}
if os.path.isfile(TABLE):
    for ln in open(TABLE, encoding="utf-8").read().splitlines():
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        f = ln.split("\t")
        if len(f) >= 3:
            mm = re.search(r"callers=(\d+)", f[2])
            if mm:
                declared[f[0]] = int(mm.group(1))
else:
    print("  [FAIL] LEG 2: %s is missing, so this leg's extractor has nothing to be"
          " cross-checked against" % TABLE)
    bad = 1
for h in HELPERS:
    mine = sum(1 for x in found if x[0] == h)
    if h not in declared:
        print("  [FAIL] LEG 2: %s declares no callers=N in %s, so a skipped invocation would"
              " be invisible here" % (h, TABLE))
        bad = 1
    elif declared[h] != mine:
        print("  [FAIL] LEG 2: %s — this leg resolved %d invocation(s); %s declares"
              " callers=%d. One of the two extractors is wrong; a silent under-count here"
              " would leave that assertion's dispatch unchecked forever."
              % (h, mine, TABLE, declared[h]))
        bad = 1

# --- VACUITY GUARD 2: the call graph must still SEE fan-out.
# If the resolver stops reading `gate_x || rc=1` bodies, every dispatch name collapses to one
# leaf and this leg goes green on a corpus it can no longer measure. At least one gate
# function must be seen calling two or more others.
fanout = sorted(f for f, kids in direct.items() if len(kids) > 1)
if not fanout:
    print("  [FAIL] LEG 2: no gate function was seen calling two others, so the call graph is"
          " inert and every dispatch name would resolve to a single gate by construction")
    bad = 1

for helper, label, mode, n in found:
    if mode is None:
        print("  [FAIL] %s:%d — no dispatch name could be read from the %s for \"%s\","
              % (src, n, helper, label))
        print("         so this leg cannot tell which gate that assertion exercises.")
        bad = 1
    elif mode not in reach:
        print("  [FAIL] %s:%d — \"%s\" names the dispatch `%s`, which the dispatch block does"
              " not define." % (src, n, label, mode))
        print("         An unknown mode prints usage and exits 2, which is a non-zero status")
        print("         a fire-proof can mistake for the gate firing.")
        bad = 1
    elif len(reach[mode]) > 1:
        print("  [FAIL] %s:%d — \"%s\" runs the dispatch `%s`, which is %d gates behind one"
              " exit code:" % (src, n, label, mode, len(reach[mode])))
        print("           %s" % ", ".join(sorted(reach[mode])))
        print("         Any of them can supply the failure, so the assertion cannot say which")
        print("         gate it exercised. Give the gate under test its own leaf dispatch")
        print("         name — GATES 10a/10b, 4b, 11-figures, 11-phrases and 4 all have one.")
        bad = 1

if not bad:
    combined = sorted(k for k, v in reach.items() if len(v) > 1)
    print("  [ok] LEG 2: %d fire-proof(s) and negative control(s) resolved through %d dispatch"
          " name(s); every one runs exactly ONE gate" % (len(found), len(disp)))
    print("       (%d combined name(s) exist and are unused by any assertion: %s; %d gate"
          " function(s) fan out)" % (len(combined), ", ".join(combined), len(fanout)))
sys.exit(bad)
PY
  echo "-- GATE 16 LEG 3: a fire-proof's expected substring names exactly ONE message --"
  python3 - <<'PY' || rc=1
import os, re, subprocess, sys

# LEG 3 (item R4, round 11 drain-1, 2026-08-02). See the gate header for why this is
# mechanical rather than the argument it replaces.
src = os.environ.get("DOC_GATES_SRC_OVERRIDE") or "scripts/doc_gates.sh"
TABLE = "documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt"
if src != "scripts/doc_gates.sh":
    print("  [note] LEG 3 scanning OVERRIDE source %s, not the live script" % src)
if not os.path.isfile(src):
    print("  [FAIL] LEG 3: %s is not a readable file, so zero substrings were resolved" % src)
    sys.exit(1)
lines = (open(src, encoding="utf-8").read() if src != "scripts/doc_gates.sh" else subprocess.run(["bash", "scripts/doc_gates.d/logical_source.sh"], stdout=subprocess.PIPE, check=True).stdout.decode("utf-8")).splitlines()
bad = 0

# --- THE MESSAGES THIS HARNESS CAN PRINT. Both forms, because it uses both: a python
# `print(...)` inside a gate body and a shell `echo "..."`. A comment cannot print, and both
# patterns are anchored at line start, so a `#` prefix excludes the line without a separate
# skip — unlike LEG 2's `uncomment`, which had to strip comments because its call pattern was
# not anchored.
STRLIT = re.compile(r"\"((?:[^\"\\]|\\.)*)\"|'((?:[^'\\]|\\.)*)'")
SPEC = re.compile(r"%[-#0 +]*[0-9]*(?:\.[0-9]+)?[sdiroxefgu]")
DIGITS = re.compile(r"[0-9]+")
PRINT_OPEN = re.compile(r"^[ \t]*print\(")
ECHO_LINE = re.compile(r'^[ \t]*echo[ \t]+"(.*)"[ \t]*$')
TPL_SPAN = 12


def norm(s, template):
    # ONE WILDCARD FOR EVERY VARYING FIELD, on both sides. A template's %-specifier and a
    # substring's digit run collapse to the same sentinel, so `is 2 gates behind one exit
    # code` resolves against `which is %d gates behind one exit code:`. Collapsing a literal
    # digit run in a template too is what keeps the two sides symmetric.
    if template:
        s = s.replace("%%", "\x01")
        s = SPEC.sub("\x00", s)
        s = s.replace("\x01", "%")
    return DIGITS.sub("\x00", s).replace('\\"', '"').replace("\\`", "`")


def literals(s):
    return "".join((m.group(1) if m.group(1) is not None else m.group(2))
                   for m in STRLIT.finditer(s))


templates, i = [], 0
while i < len(lines):
    ln = lines[i]
    if PRINT_OPEN.match(ln):
        buf, depth, j = "", 0, i
        while j < len(lines) and j - i < TPL_SPAN:
            seg = lines[j]
            buf += literals(seg[seg.index("print(") + 6:] if j == i else seg)
            depth += seg.count("(") - seg.count(")")
            if depth <= 0:
                break
            j += 1
        templates.append((i + 1, "print", norm(buf, True)))
        i = j + 1
        continue
    m = ECHO_LINE.match(ln)
    if m:
        templates.append((i + 1, "echo", norm(m.group(1), True)))
    i += 1

# --- VACUITY GUARD 1: neither message form may go quiet. This is LEG 1's per-preflight guard
# applied to a set of two: a rewrite of every `print` to some other call, or of every `echo`,
# would silently halve the comparison and every substring would still resolve against what
# was left. A count nobody reads is not a check.
for kind in ("print", "echo"):
    if not any(t[1] == kind for t in templates):
        print("  [FAIL] LEG 3: zero `%s` message templates extracted from %s, so that half of"
              " this harness's output is outside the comparison" % (kind, src))
        print("         A substring resolving uniquely against the remaining half would")
        print("         still print [ok] — the false-clear shape GATE 16 exists to refuse.")
        bad = 1

# --- THE FIRE-PROOF DRIVERS, DISCOVERED RATHER THAN NAMED. A driver is a helper whose body
# asserts on its second argument with a fixed string. Naming them here would be a population
# statement in a comment, which this file has now falsified in its own diff more than once.
DRIVER_DEF = re.compile(r"^[ \t]*(_g[A-Za-z0-9_]+)\(\)[ \t]*\{[ \t]*(?:#.*)?$")
QF_ARG = re.compile(r"grep[ \t]+-qF[ \t]+\"\$2\"")
drivers, spans = [], []
for i, ln in enumerate(lines):
    m = DRIVER_DEF.match(ln)
    if not m:
        continue
    stop = next((j for j in range(i + 1, min(i + 41, len(lines)))
                 if lines[j].strip() == "}"), None)
    if stop is None:
        continue
    if any(QF_ARG.search(lines[j]) for j in range(i + 1, stop)):
        drivers.append(m.group(1))
        spans.append((i + 1, stop + 1))

# --- VACUITY GUARD 2: every fixed-string-on-$2 assertion in the file must belong to a driver
# this leg found. A driver written in a shape DRIVER_DEF cannot read would otherwise take its
# assertions out of scope silently, which is the one failure this leg cannot survive: it would
# report [ok] over a smaller population and nothing would say so.
orphan = [i + 1 for i, ln in enumerate(lines)
          if QF_ARG.search(ln) and not any(a <= i + 1 <= b for a, b in spans)]
if orphan:
    print("  [FAIL] LEG 3: %s asserts on a fixed `$2` outside any driver this leg could read:"
          " %s" % (src, ", ".join(str(o) for o in orphan)))
    print("         The driver definition must open its body on its own line (`_gX() {`) or")
    print("         this leg stops seeing that driver's substrings while still saying [ok].")
    bad = 1
if not drivers:
    print("  [FAIL] LEG 3: zero fire-proof drivers found in %s — the scan is inert, not clean"
          % src)
    bad = 1

# --- VARIABLE-CARRIED ASSERTIONS (round 11 drain-2, 2026-08-02, from drain-1's could-not-see
# column). A fire-proof does not have to put its expected substring at the call site. GATE 15
# LEG 2's pair selects its substring in a `case` arm and asserts on the variable, and those
# substrings are fire-proof substrings by every property this leg cares about. They were
# outside it in BOTH directions, which is why nothing said so: not a driver positional, so
# never parsed; and not matched by guard 2's QF_ARG either, so not an orphan. A population
# that is invisible to both the scan and the scan's own vacuity guard is the exact state this
# leg exists to refuse, one level up from the drivers it already reads.
#
# THE SORT IS EXHAUSTIVE ON PURPOSE. Every fixed-string assertion whose pattern is an
# expansion must land in one of two bins — a driver's positional, handled by guard 2 above,
# or a named variable, resolved below. A third form is a FAIL, not a shrug: an assertion this
# leg cannot classify is one it stops resolving while still printing [ok].
QF_ANY = re.compile(r"grep[ \t]+-qF[ \t]+\"\$")
QF_VAR = re.compile(r"grep[ \t]+-qF[ \t]+\"\$([A-Za-z_][A-Za-z0-9_]*)\"")
varsites = {}
for i, ln in enumerate(lines):
    if ln.lstrip().startswith("#") or not QF_ANY.search(ln) or QF_ARG.search(ln):
        continue
    m = QF_VAR.search(ln)
    if m:
        varsites.setdefault(m.group(1), i + 1)
        continue
    print("  [FAIL] LEG 3: %s:%d — a fixed-string assertion reads an expansion this leg sorts"
          " into neither a driver's positional nor a named variable:" % (src, i + 1))
    print("           %s" % ln.strip())
    print("         Its substring is a fire-proof substring and is now outside the")
    print("         exactly-one-template rule, with nothing but this line to say so.")
    bad = 1

varfound = []
for v, site in sorted(varsites.items()):
    apat = re.compile(r"(?:^|[ \t;&|(])" + re.escape(v) + r"=(.*)$")
    occ = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(v) + r"(?![A-Za-z0-9_])")
    use = '"$' + v + '"'
    seen = 0
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith("#") or not occ.search(ln):
            continue
        am = apat.search(ln)
        if am:
            rhs = am.group(1)
            # literals() is the SAME concatenating reader the template side uses, which is
            # what makes `x='a'"'"'b'` resolve to the one string the shell builds rather than
            # to its first fragment. The residue test is the guard on that: if anything
            # OUTSIDE the quotes expands, the reconstruction is a fragment of the real
            # substring and comparing it would be a clear taken on partial text.
            lit = literals(rhs)
            if "$" in STRLIT.sub("", rhs) or not lit:
                print("  [FAIL] LEG 3: %s:%d — `$%s` is assigned from something this leg"
                      " cannot read as a whole literal:" % (src, i + 1, v))
                print("           %s" % ln.strip())
                print("         Resolving a FRAGMENT of a fire-proof's substring against the")
                print("         message set would be a verdict taken on partial text.")
                bad = 1
                continue
            varfound.append((v, lit, i + 1))
            seen += 1
        elif use not in ln:
            # VACUITY GUARD 4, and it is derived by a DIFFERENT rule from the assignment scan
            # above: bare occurrence of the name, not assignment shape. An assignment written
            # in a form `apat` cannot read would otherwise drop its substring out of the
            # comparison in silence — the under-count shape guards 2 and 3 exist for, which
            # this population would otherwise reintroduce.
            print("  [FAIL] LEG 3: %s:%d — `$%s` occurs here as neither a literal assignment"
                  " this leg resolved nor the assertion itself:" % (src, i + 1, v))
            print("           %s" % ln.strip())
            print("         An assignment in a shape the scan cannot read takes its substring")
            print("         out of the comparison while this leg still prints [ok].")
            bad = 1
    if not seen:
        print("  [FAIL] LEG 3: %s:%d — the fire-proof asserts on `$%s`, a variable this leg"
              " found no literal assignment for" % (src, site, v))
        print("         The string it greps the gate's output for is then unknown here, so")
        print("         the exactly-one-template rule was never applied to that assertion.")
        bad = 1

SUB_LINE = re.compile(r"^[ \t]*'((?:[^'\\]|\\.)*)'")
found = []
for d in drivers:
    one = re.compile(r"^[ \t]*" + re.escape(d) + r"[ \t]+\"((?:[^\"\\]|\\.)*)\"[ \t]+"
                     r"'((?:[^'\\]|\\.)*)'")
    wrap = re.compile(r"^[ \t]*" + re.escape(d) + r"[ \t]+\"((?:[^\"\\]|\\.)*)\"[ \t]*\\[ \t]*$")
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith("#"):
            continue
        m = one.match(ln)
        if m:
            found.append((d, m.group(1), m.group(2), i + 1))
            continue
        m = wrap.match(ln)
        if m and i + 1 < len(lines):
            m2 = SUB_LINE.match(lines[i + 1])
            if m2:
                found.append((d, m.group(1), m2.group(1), i + 1))

# --- VACUITY GUARD 3: an INDEPENDENTLY-DERIVED count of the same call sites, exactly as
# LEG 2's guard 1 above. GATE 15 LEG 3 machine-checks a `callers=N` for each driver by a
# different rule (name in command position over the whole file). Two extractors written for
# different purposes must agree, or one of them is wrong.
declared = {}
if os.path.isfile(TABLE):
    for ln in open(TABLE, encoding="utf-8").read().splitlines():
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        f = ln.split("\t")
        if len(f) >= 3:
            mm = re.search(r"callers=(\d+)", f[2])
            if mm:
                declared[f[0]] = int(mm.group(1))
elif drivers:
    print("  [FAIL] LEG 3: %s is missing, so this leg's extractor has nothing to be"
          " cross-checked against" % TABLE)
    bad = 1
for d in drivers:
    mine = sum(1 for x in found if x[0] == d)
    if d not in declared:
        if os.path.isfile(TABLE):
            print("  [FAIL] LEG 3: %s declares no callers=N in %s, so a substring this leg"
                  " failed to parse would be invisible" % (d, TABLE))
            bad = 1
    elif declared[d] != mine:
        print("  [FAIL] LEG 3: %s — this leg parsed %d substring(s); %s declares callers=%d."
              " One of the two extractors is under-reading, and an unparsed invocation is an"
              " unchecked substring." % (d, mine, TABLE, declared[d]))
        bad = 1

for d, label, sub, n in found:
    want = norm(sub, False)
    hits = [t for t in templates if want in t[2]]
    if len(hits) == 1:
        continue
    if not hits:
        print("  [FAIL] LEG 3: %s:%d — %s(\"%s\") asserts a substring no message template can"
              " produce:" % (src, n, d, label))
        print("           %s" % sub)
        print("         The driver greps for that fixed string in the gate's output, so the")
        print("         leg can now only ever report NOT reported. This is a message reworded")
        print("         out from under its own fire-proof, caught at the source instead of at")
        print("         the next run that happens to exercise it.")
    else:
        print("  [FAIL] LEG 3: %s:%d — %s(\"%s\") asserts a substring %d message templates can"
              " produce:" % (src, n, d, label, len(hits)))
        print("           %s" % sub)
        for t in hits[:6]:
            print("           -> %s:%d (%s)" % (src, t[0], t[1]))
        print("         The assertion cannot then say WHICH finding satisfied it, and a leg")
        print("         satisfied by a different finding in the same output is green for the")
        print("         wrong reason — which is the entire content of a fire-proof.")
    bad = 1

# THE VARIABLE-CARRIED HALF GETS ITS OWN VERDICT LINE, and that is not duplication. Both
# directions collapse into one message here because the site is an ASSIGNMENT, not a call —
# there is no driver and no label to name — and because a fire-proof for this half must be
# able to assert on a string the driver half cannot also print. Sharing the driver wording
# would have made the two halves indistinguishable in the output, which is the very confusion
# this leg refuses one level down.
for v, sub, n in varfound:
    want = norm(sub, False)
    hits = [t for t in templates if want in t[2]]
    if len(hits) == 1:
        continue
    print("  [FAIL] LEG 3: %s:%d — `$%s` carries a fire-proof literal %d message template(s)"
          " can produce; exactly one is required:" % (src, n, v, len(hits)))
    print("           %s" % sub)
    for t in hits[:6]:
        print("           -> %s:%d (%s)" % (src, t[0], t[1]))
    print("         Zero means a message was reworded out from under an assertion that can")
    print("         now only ever report NOT reported; more than one means the assertion")
    print("         cannot say which finding satisfied it. Both are green for a wrong reason.")
    bad = 1

if not bad:
    print("  [ok] LEG 3: %d fire-proof substring(s) across %d driver(s) (%s), plus %d carried"
          " by %d asserted variable(s), each produced by exactly ONE of %d message template(s)"
          % (len(found), len(drivers), ", ".join(sorted(drivers)), len(varfound),
             len(varsites), len(templates)))
    print("       caveat (g): ONE template is not one INSTANTIATION — a substring spanning a"
          " %-field still cannot say which call printed it")
sys.exit(bad)
PY
  return $rc
}

