#@ scripts/doc_gates.d/80_repro_reach_claim_shapes.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATES 25-38: repro-reach, canonical ceiling, withdrawn markers, framing, claim-shape gates.
#@ Lines 14247-16412 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# ---------------------------------------------------------------------------
# GATE 25 — a documented reproduction command must be RUNNABLE (#213 D).
#
# WHY THIS EXISTS (measured, 2026-08-11). GATE 2 is ONE-DIRECTIONAL: "CLI flags live
# in code but undocumented" (code -> doc). The reverse was uncovered — a DOC naming a
# flag that does not exist in the code. That is exactly an unreachable reproduction
# command, and no existing gate could see it: GATE 1 checks anchors are still present,
# GATE 3b that retracted numbers do not reappear, GATE 5b that canonical quantities
# carry an epistemic marker, GATE 6 that figure GENERATORS (plots) carry no retracted
# phrasing. None asks "can a reader actually run the command this figure cites?"
#
# FIRST RUN found TR-11 v1.18's revision row citing `verify.py --recount-c5-rung 18`,
# a flag that has never existed on any ref. The body carried the same error and
# 5d04b8d6 fixed it the same day but missed the identical string 70 lines below —
# i.e. a human correction pass had already looked at this and half-fixed it. Repaired
# in 93878a18 (TR-11 v1.19).
#
# WHY A NARRATION REGISTRY, NOT A PURE SCANNER. Two legitimate cases name a flag that
# does not exist, and both are CORRECT documentation:
#   (a) a correction must name the command it corrects;
#   (b) a doc may document NON-existence to warn readers away — SOLVE_C_CLI.md:738
#       reads "`solve --extended-selftest` is not dispatched by the binary".
# This is the same legitimate-restatement problem GATE 3b solved for retracted figures,
# and it is handled the same way GATE 21 handles unresolvable script paths: resolve, OR
# be declared narration with a stated reason. Every waiver below names WHY, so a stale
# one is visible. Case (a) additionally has a CONVENTION: a correction cites the BARE
# flag, never the invocation form, so the extractor never sees it. That convention is
# load-bearing — if a correction writes the invocation form this gate FAILS, and the fix
# is to reword the correction, not to widen the extractor.
#
# PROMOTED INTO 'all' ON 2026-09-02 (batch C7), and the honest basis for it is recorded here
# rather than implied. This header used to read "NOT IN 'all' YET ... promote only after it has
# been observed silent across a full corpus for a while; that promotion is a deliberate
# decision, not a default." The DELIBERATE half is satisfied — it was decided, with reasons.
# 🔴 THE OBSERVATION WINDOW IS NOT. LEG 1 had been RED, on two false positives, and was made
# clean the same day it was promoted; it has not been silent "for a while" and no reader should
# infer that it has. What was substituted for the window, deliberately, is EVIDENCE:
#   * both red lines were shown to be false positives at the source, not reworded away;
#   * the fix was red-tested three ways (a genuine unreachable command still FAILS in isolation,
#     a proposal passes, and a genuine command adjacent to a proposal still FAILS);
#   * LEG 1 accumulates EVERY unresolved flag before printing, so the two known reds could not
#     have masked a third — measured: 18 unreachable sites, 13 declared narration, 5 proposals,
#     0 remaining;
#   * LEG 2 cannot move the exit code (`sys.exit(1 if bad else 0)`, and nothing in LEG 2 touches
#     `bad`), so promoting the gate promotes only LEG 1;
#   * cost is not an argument here the way it is for GATE 8: measured 0.89-0.99 s over three runs.
#
# 🔴 THE RESIDUAL RISK, stated because promotion makes it blocking. This gate is WORDING-
# SENSITIVE by design — the convention note above says so ("if a correction writes the
# invocation form this gate FAILS, and the fix is to reword the correction"). A future doc that
# discloses a missing mode in the invocation form, using proposal language OUTSIDE the three
# markers in PROPOSAL below, will block every push until either the wording or that list moves.
# Two of the five proposal sites in the corpus were written in the three days before promotion,
# by exactly that activity. Extending PROPOSAL is a one-line change; REWORDING THE CORPUS TO
# SATISFY THIS GATE IS NOT THE FIX, per GATE 7's header. If that trade proves wrong, the
# revert is this gate's line in the `all` dispatch arm and the two banner lines that name it.
gate_repro_reach() {
  echo "== GATE 25: every documented reproduction command resolves to a real flag =="
  # Q-703 (2026-09-24, Fable K): the population is the script's own $DOCS (git ls-files '*.md'),
  # passed in by environment because the heredoc is quoted. See the `docs =` note below.
  { _wm_prelude; cat <<'PY'
import bisect, os, re, sys

TOOLS = {"verify.py": "verify.py", "solve.py": "solve.py", "sat.py": "sat.py",
         "roae.py": "roae.py", "solve": "solve.c", "verify": "verify.c"}
BUILTIN = {"--help"}          # argparse builtins are never source literals

# Declared narration: flag does not exist AND the doc is right to name it.
NARRATION = {
    ("solve", "--verify-superset"):       "removed subcommand, cited in HISTORY/PERFORMANCE_HISTORY",
    ("solve", "--depth-profile"):         "removed subcommand, cited in HISTORY",
    ("solve", "--branch-yield-report"):   "removed subcommand, cited in LARGE_SCALE_CAMPAIGNS",
    ("solve", "--constraint-spec"):       "removed subcommand, cited in LARGE_SCALE_CAMPAIGNS",
    ("solve.py", "--compare-leaf-rates"): "removed subcommand, cited in DEVELOPMENT/HISTORY",
    ("solve", "--extended-selftest"):     "documented NON-existence; SOLVE_C_CLI.md:738 warns readers away",
    ("solve", "--kc-repr-normalize"):     "documented NON-existence (case b); lives only on the public tag v4-repr-fc-legc-20260813 (5f473242), on no branch (re-measured 2026-10-02). VERIFY.md carries a NOT-AVAILABLE box, and both invocation-form cite sites were given an inline warning 2026-08-16 so a reader entering the file at either one cannot be misled. Retire this row if the engine lands on main.",
    ("solve", "--orbit-selftest"):       "documented NON-existence on main; the self-test of the v4 orbit engine, which exists only on the public tags (v4-repr-fc-legc-20260813, archive/orbit-port-188-candidate-20260824, archive/v4-canonical-20260824). Cited in BRANCHES_EXPLAINED.md §\"Decision 2026-10-02\" inside a block that first checks out the tag; operator decision 2026-10-02 (CX-273) keeps that engine off main for good.",
}
# 🔴 Q-966 (A08#3, 2026-10-03): A NARRATION ROW IS BOUND TO THE DOCUMENTS THAT NARRATE THE FLAG. Keyed
# on (tool, flag) alone, "To reproduce the result, run `solve --extended-selftest`." passed in ANY
# document, because SOLVE_C_CLI.md warns readers away from that flag. NARRATION_AT lists, per row, the
# documents whose citations it waives (measured 2026-10-03: every waived site at the time); the two
# append-only ledgers are in every row, since quoting a removed flag verbatim is what they are for. A
# row with no NARRATION_AT entry waives nothing, and is reported.
_NARR_LEDGERS = {"documentation/CORRECTIONS.md", "documentation/HISTORY.md"}
NARRATION_AT = {
    ("solve", "--verify-superset"):       {"documentation/PERFORMANCE_HISTORY.md"},
    ("solve", "--depth-profile"):         set(),
    ("solve", "--branch-yield-report"):   {"documentation/LARGE_SCALE_CAMPAIGNS.md"},
    ("solve", "--constraint-spec"):       {"documentation/LARGE_SCALE_CAMPAIGNS.md"},
    ("solve.py", "--compare-leaf-rates"): {"documentation/DEVELOPMENT.md"},
    ("solve", "--extended-selftest"):     {"documentation/SOLVE_C_CLI.md"},
    ("solve", "--kc-repr-normalize"):     {"documentation/VERIFY.md"},
    ("solve", "--orbit-selftest"):        {"documentation/BRANCHES_EXPLAINED.md"},
}
if set(NARRATION) - set(NARRATION_AT):
    for _k in sorted(set(NARRATION) - set(NARRATION_AT)):
        print("  [FAIL] NARRATION row %s %s has no NARRATION_AT entry; bind it to the documents that"
              " narrate it" % _k)
    sys.exit(1)

# CODEX N10 FINDING 13 HALF A, adjudicated 2026-09-03. The extractor was
# `((?:--[a-z0-9][a-z0-9-]*\s*)+)` — an INITIAL RUN of VALUELESS flags. It stopped dead at the
# first flag that takes a value, so in Codex's construction
#
#     solve --depth 3 --definitely-not-a-flag
#
# it extracted `--depth` and the invalid trailing flag was never examined. Every documented
# command of the form `--flag VALUE --other-flag` was checked to its first value and no
# further, while the gate's own [ok] line claims "every documented reproduction command
# resolves to a real flag".
#
# WHAT REPLACES IT, and why not simply "read to end of line". A regex that swallows the rest
# of the line finds 1,238 flag uses against the old 1,085 — and the extra 153 are markdown and
# prose, measured: `roae.py --verify, doc gates`, `solve --merge) instead of running fresh
# sha256sum — fast`, `--json|--csv|--svg|...` alternation lists, `[--sat-c3 pb]` optional-arg
# notation. Attributing those to the tool is how a blocking gate starts firing on correct
# prose. So the walk is TOKENWISE and CONSERVATIVE: a `--flag` is a flag, at most ONE
# value-shaped token may follow each flag, and the command ENDS at the first token that is
# neither (and at a backtick or a newline, whichever comes first).
#
# MEASURED over the live corpus before landing: old 1,085 uses / 8 distinct unresolved;
# tokenwise 1,125 uses / 8 distinct unresolved — 40 newly examined flag uses, ZERO new
# unresolved flags and ZERO previously-found ones lost. The widening is therefore inert on
# today's corpus and cannot start blocking a push on existing content; it closes the hole for
# the next command somebody documents with a value in the middle.
#
# WHAT IT STILL CANNOT SEE, stated rather than implied: 52 sites carry a `--flag` after a token
# this walk refuses (bracketed optionals `[--sat-c4]`, `|`-alternation lists, shell operators).
# Those are UNDER-coverage, not false clears — the same trade GATE 25's header already makes.
# The left boundary is load-bearing: without it the bare alternatives `solve`/`verify` match
# the TAIL of a longer token, so a prose list of flags such as
# `--kc-ladder-verify --kc-midn` parsed as the command `verify --kc-midn` and reported five
# real solve.c flags as "not a flag of verify.c" (found 2026-09-05 when QUERY_INVENTORY.md
# landed). `/` is deliberately NOT in the class, so `scripts/solve.py --flag` still matches.
HEAD_RE = re.compile(r'(?<![-A-Za-z0-9_.])'
                     r'(?:python3?\s+)?(?:\./)?'
                     r'(verify\.py|solve\.py|sat\.py|roae\.py|solve|verify)\s+'
                     r'(?=--[a-z0-9])')
FLAGTOK = re.compile(r'^--[a-z0-9][a-z0-9-]*$')
VALTOK  = re.compile(r'^[-A-Za-z0-9_./:=*%+~^@\[\]{}<>,]*[-A-Za-z0-9_./:=*%+~^@\]}>]$')

def _command_flags(text, at):
    """Flags of the invocation whose flag run begins at offset `at`. At most one value-shaped
    token may follow each flag; the command stops at the first token that is neither, and
    never crosses a backtick or a newline."""
    stop = text.find("\n", at)
    if stop < 0:
        stop = len(text)
    tick = text.find("`", at)
    if 0 <= tick < stop:
        stop = tick
    flags, pend = [], False
    for tok in text[at:stop].split():
        base = tok.split("=", 1)[0]
        if tok.startswith("--") and FLAGTOK.match(base):
            flags.append(base)
            pend = True
        elif pend and not tok.startswith("-") and VALTOK.match(tok):
            pend = False          # this token is the preceding flag's VALUE
        else:
            break
    return flags

# PROPOSAL MARKERS (added 2026-09-02, batch C7) — a doc that names a flag it is PROPOSING,
# not claiming. LEG 1 could not tell "run this" from "we should build this", so it fired on
# four PROJECT_OVERVIEW/SOLVE/SOLVE_SUMMARY/SPECIFICATION sites whose own sentence disclaims
# the figure the flag would reproduce ("the outstanding fix is a `solve.py --extraction-null`
# mode") and on CORRECTIONS.md:4684 ("It is queued to the code lane ... and a
# `verify.py --twins-bisect` flag"). Every one is the project being scrupulous about what does
# NOT exist. A gate that gets louder the more honestly the corpus describes its own gaps has
# the wrong gradient — this file's GATE 7 header records rewording the corpus to satisfy an
# instrument as "the worst way to pay for a false positive".
#
# 🔴 SCOPE WAS CHOSEN BY MEASUREMENT, AND THE FIRST TWO CANDIDATES WERE BOTH REFUTED.
#   * SAME-LINE (the scope ced18ec9 landed for GATE 7) is INSUFFICIENT here: it clears all four
#     --extraction-null sites and MISSES CORRECTIONS.md:4684, where the marker "is queued to the
#     code lane" ends line 4658 and the invocation opens 4659. Markdown hard-wrap, not a
#     coincidence of adjacency — it is one sentence.
#   * WHOLE-SENTENCE (bounded only by terminators and blank lines) is far WORSE than the ±4/+3
#     window ced18ec9 rejected: measured over this corpus the longest such span is 57 newlines /
#     4,924 chars in SOLVE_C_CLI.md and swallows 45 command-flag sites in one gulp, because a
#     fenced block or table carries no sentence terminator at all.
#   * WHAT SHIPPED: the sentence containing the flag, reconstructed across AT MOST ONE hard-wrap
#     (the immediately preceding line, and never across a blank line). Bounded by construction to
#     two physical lines, and on a wall-of-text line it is strictly NARROWER than line scope
#     because it stops at the sentence boundary. It also reproduces ced18ec9's recall result: an
#     unrelated marker on the preceding line does NOT suppress, because a preceding line that
#     ends a sentence is outside the span — the association has to be grammatical.
#   * 🔴 THE SHIPPED ARM WAS ASYMMETRIC UNTIL 2026-09-03 — it walked BACKWARDS only, so a flag
#     whose proposal marker sits on the FOLLOWING wrapped line read as a broken command and,
#     since promotion into `all`, blocked the push. Prose batch P54 hit it in its own ledger
#     text. A FORWARD arm now mirrors the backward one (see `_proposal_scope`). MEASURED before
#     landing over the live corpus: 1,082 command-flag uses, 13 narration waivers, 7 proposal
#     waivers, 0 unreachable — IDENTICAL with and without the forward arm, i.e. zero live delta,
#     so this widens no existing waiver. Red-tested on a four-case fixture (a real-source
#     scratch tree, symlinked verify.py/solve.py/sat.py/roae.py/solve.c/verify.c): forward-wrap
#     marker -> false FAIL before, [prop] after; a genuine unreachable flag with no marker ->
#     FAIL both; a marker on the next line that STARTS a new sentence -> FAIL both (recall
#     preserved, the same result ced18ec9 established for the backward direction); backward-wrap
#     marker -> [prop] both.
#
# MEASURED over the real corpus at the time of the change: 18 sites cite a flag that does not
# exist. This waives EXACTLY the 5 proposal sites; the other 13 are the NARRATION-registry rows
# and every one still fires. Zero collateral. Ambient reachability, for the next person changing
# this list: 'queued' appears 79 times in 21 files, 'outstanding fix' 6 times in 5.
#
# DELIBERATELY NOT ADDED — 'does not exist' (21 occurrences, 11 files). Documented NON-existence
# is case (b) in this gate's header and it is ALREADY handled, by a NARRATION row that must state
# a reason so a stale waiver is visible. An automatic marker for it would open a second,
# unreviewable path to the same waiver and quietly retire that review. Also not added: 'proposed',
# 'would be', 'planned' — each matches ordinary prose far more often than it matches a proposal.
#
# WAIVERS ARE PRINTED, not merely counted: a proposal that is never built must stay visible.
PROPOSAL = ['queued', 'outstanding fix', 'not yet implemented', 'pending flag', 'pending --']
# 🔴 Q-966 (A08#4, 2026-10-03): each marker is matched through the shared word matcher
# (scripts/doc_gates.d/word_match.sh) -- WHOLE WORDS, and not when negated -- and 'queued' only as a
# PREDICATE of the thing proposed ("it is queued to the code lane", "queued for ..."). As a substring,
# "Run the queued job with `solve --q835-absent`." waived a flag that does not exist: the job was
# queued, not the flag. Measured 2026-10-03: the live corpus has 1 proposal waiver ('pending flag').
PROPOSAL_RX = [
    ('queued', wm_re(r'(?:is|are|was|were|been|being|be|stays?|remains?)\s+(?:still\s+|now\s+|also\s+)?queued'
                     r'|queued(?=\s+(?:to|for)\b)')),
    ('outstanding fix', wm_re(r'outstanding\s+fix')),
    ('not yet implemented', wm_re(r'not\s+yet\s+implemented')),
    ('pending flag', wm_re(r'pending\s+flag')),
    ('pending --', wm_re(r'pending(?=\s+--)')),
]
if [k for k, _ in PROPOSAL_RX] != PROPOSAL: raise SystemExit('PROPOSAL_RX keys drifted from PROPOSAL')   # explicit, survives -O (Q-373)
# 'pending flag' and 'pending --' (Q-703, 2026-09-24, Fable K; NARROWED the same day by the batch-2
# pre-publication review, item S2, Fable P) are the two forms the viz/ pages use for a flag they
# PROPOSE: "### PENDING flag (proposed name — TR-12 §8 should pin it before it is built)" as a
# fence caption, and "# 1. the grid  (PENDING --kc-unrank-grid)" on the line before the command.
# 🔴 THE BARE MARKER 'pending' SHIPPED FIRST AND FAILED OPEN, MEASURED: against a lower-cased
# sentence scope and (new in Q-703) a lower-cased fence caption, "Results are pending review:"
# above a fence and "(the pending rerun)" in a sentence each waived a MISSPELT flag as a [prop]
# line, rc 0 — 'pending' is on 317 lines of 51 files at 5c296837, and "a marker is consulted
# only for a flag that failed to resolve" bounds how OFTEN it fires, not WHAT it waives. The
# two-word forms are what the corpus actually writes for a proposal; at 5c296837 the real corpus
# yielded exactly 2 [prop] waivers (`solve --kc-unrank-grid`, viz/viz_kc_spectrum.md:94@5c296837 caption,
# :232 sentence; 1 since 2026-09-25, Q-703), and the two probes above now FAIL. Fire-proven in --selftest
# ("GATE 25 (S2) ordinary 'pending' prose does not waive"). Every waiver granted is printed as
# a [prop] line, never silently counted.

def _fence_caption(lines, i):
    """Q-703. When lines[i] sits INSIDE a fenced code block, the block's caption: the nearest
    non-blank line above the OPENING fence, lower-cased. A synopsis block is labelled by the
    heading or sentence that introduces it, not by a sentence of its own — the sentence scope
    above sees only the fence line. Returns '' when lines[i] is not inside a fence, so this
    never widens the scope of a command written in prose."""
    inside, opening = False, -1
    for j in range(i):
        if lines[j].lstrip().startswith(("```", "~~~")):
            inside = not inside
            opening = j
    if not inside:
        return ''
    k = opening - 1
    while k >= 0 and not lines[k].strip():
        k -= 1
    return lines[k].lower() if k >= 0 else ''

def _proposal_scope(lines, i, col):
    """The sentence containing column `col` of lines[i], reconstructed across at most one
    hard-wrap IN EACH DIRECTION. Returns lowercase text. Never crosses a blank line."""
    cur = lines[i]
    prev = lines[i - 1] if i > 0 else ""
    if not prev.strip():
        joined, pos = cur, col
    else:
        joined, pos = prev + " " + cur, len(prev) + 1 + col
    # FORWARD ARM (2026-09-03, wave-3 lane A). The backward-only walk was ASYMMETRIC: a flag
    # whose proposal marker sits on the FOLLOWING wrapped line read as a broken command and
    # blocked the push. Found by prose batch P54 hitting it in its own ledger text. The
    # extension is grammatical, not positional — `e` below still stops at the first sentence
    # terminator after `pos`, so the next line enters the span ONLY when the sentence really
    # continues onto it; a next line that starts a NEW sentence is outside the span exactly as
    # a preceding line that ENDS one already is. Bounded by construction to three physical
    # lines, never across a blank line.
    nxt = lines[i + 1] if i + 1 < len(lines) else ""
    if nxt.strip():
        joined = joined + " " + nxt
    s = 0
    for mm in re.finditer(r'(?<=[.!?])\s', joined[:pos]):
        s = mm.end()
    e = len(joined)
    mm = re.search(r'(?<=[.!?])\s', joined[pos:])
    if mm:
        e = pos + mm.end()
    return joined[s:e].lower()

# CODEX N10 FINDING 13 HALF B, adjudicated 2026-09-03. `have[tool]` is every quoted
# `--...` string ANYWHERE in the tool's source — comments, dead code and narration included —
# and it is used as the set of flags that EXIST. So a fake flag mentioned in a source comment
# legitimises the same fake flag in a doc, and the [ok] line still says the documented command
# resolves. The acceptance set is not an implementation set.
#
# 🔴 WHAT IS NOT BUILT HERE, AND WHY, because the obvious fix is the wrong one. Stripping
# comments before extracting would need a real C/Python lexer inside a gate that is BLOCKING at
# pre-push: one mis-parsed string literal removes a REAL flag from `have`, and every doc citing
# it FAILS. Measured, that fix would buy nothing today — an inline-comment stripper and the raw
# scan return the SAME set for all six tools (roae.py 60/60, sat.py 14/14, solve 84/84,
# solve.py 99/99, verify 44/44, verify.py 42/42; zero comment-only flags). So the acceptance
# set is left exactly as it was — nothing that passes today can start failing.
#
# WHAT IS BUILT is the assertion, in the direction that cannot false-clear and needs no lexer:
# a flag whose ONLY quoted occurrence in the source sits on a WHOLE-LINE comment (the line's
# first non-space run is `#`, `//`, `*` or `/*`) is not an implementation, and if a doc cites it
# that is reported. Whole-line detection needs no string-literal parsing, which is where a
# lexer's false positives come from. MEASURED: 0 such flags across all six tools today, so this
# arm is silent on the live corpus and its count is printed even when zero (Q-284's rule).
_CMT_LINE = re.compile(r'^\s*(?:#|//|\*|/\*)')
_QFLAG = re.compile(r'"(--[a-z0-9][a-z0-9-]*)"|\'(--[a-z0-9][a-z0-9-]*)\'')

have = {}
comment_only = {}
for tool, src in sorted(TOOLS.items()):
    try:
        t = open(src, encoding="utf-8", errors="replace").read()
    except OSError as exc:
        print("  [FAIL] cannot read %s, so ZERO commands were checked for %s: %s"
              % (src, tool, exc))
        sys.exit(1)
    have[tool] = (set(re.findall(r'"(--[a-z0-9][a-z0-9-]*)"', t))
                  | set(re.findall(r"'(--[a-z0-9][a-z0-9-]*)'", t)))
    if not have[tool]:
        print("  [FAIL] zero flags parsed from %s — vacuous, treated as failure." % src)
        print("         If the declaration style changed, update this gate; do not delete it.")
        sys.exit(1)
    # 🔴 Q-966 (A08#2, 2026-10-03): the code view is the source with EVERY comment blanked by the shared
    # matcher (scripts/doc_gates.d/word_match.sh: tokenize for .py, a string-aware lexer for .c), not
    # only whole-line ones. `pass  # "--q835-absent"` appended to verify.py made a flag that nothing
    # implements "code". The lexer-risk paragraph above was about REMOVING real flags from `have`;
    # `have` is still the raw scan, so a mis-lex can only report a flag as comment-only, loudly. Measured
    # 2026-10-03: the five other tools have no comment-only flag; solve.c has three comment fragments
    # (--kc-alt, --kc-braket, --kc-witnes) and no document cites any of them.
    try:
        _code = wm_strip_comments(t, "py" if src.endswith(".py") else "c")
    except Exception as exc:
        print("  [FAIL] cannot separate code from comments in %s (%s), so its flags were not checked" % (src, exc))
        sys.exit(1)
    in_code = set()
    for _line in _code.split("\n"):
        if _CMT_LINE.match(_line):
            continue
        for _m in _QFLAG.finditer(_line):
            in_code.add(_m.group(1) or _m.group(2))
    comment_only[tool] = have[tool] - in_code

# 🔴 Q-703 (2026-09-24, Fable K). This was a HAND-WRITTEN glob list — documentation/*.md,
# reports/*.md, *.md, reports/**/*.md — and it never scanned viz/ (10 pages, 37 tool invocations
# with flags), lean/README.md, example/*.md or scripts/**/*.md. Measured at 5c296837 in a scratch
# clone: shipped 83 docs / 1,418 flag uses / [ok]; the same gate over $DOCS 97 docs / 1,500 uses /
# `[FAIL] solve --kc-unrank-grid — not a flag of solve.c` (viz/viz_kc_spectrum.md). The population
# is now the script's $DOCS, the same `git ls-files '*.md'` every other gate reads, so a new
# directory of markdown is in scope the day it is tracked. The count is printed as a bare token
# so a pre-push log can be grepped for the population that was actually scanned.
docs = sorted(set(l for l in os.environ.get("DOC_GATES_DOCS", "").split("\n") if l.strip()))
if not docs:
    print("  [FAIL] zero docs scanned — vacuous, treated as failure (DOC_GATES_DOCS was empty;"
          " the script's own DOCS guard should have refused before this point).")
    sys.exit(1)
print("GATE25_POPULATION_FROM_DOCS=%d" % len(docs))

total = waived = 0
proposals = []
bad = {}
cited_comment_only = {}   # finding 13 half B: doc cites a flag witnessed only by a comment
for d in docs:
    text = open(d, encoding="utf-8", errors="replace").read()
    lines = text.split("\n")
    offs, acc = [], 0
    for ln in lines:
        offs.append(acc)
        acc += len(ln) + 1
    for m in HEAD_RE.finditer(text):
        tool = m.group(1)
        i = bisect.bisect_right(offs, m.start()) - 1
        scope = None                      # computed lazily; only unreachable flags need it
        for fl in _command_flags(text, m.end()):
            # A trailing hyphen is never a real flag: it is the stub of a family template
            # the extractor truncated — `solve --null-<family>`, `--null-*`.
            if fl.endswith("-") or fl in BUILTIN:
                continue
            total += 1
            if fl in have[tool]:
                if fl in comment_only[tool]:
                    cited_comment_only.setdefault((tool, fl), set()).add(d)
                continue
            if (tool, fl) in NARRATION and d in (NARRATION_AT.get((tool, fl), set()) | _NARR_LEDGERS):
                waived += 1
                continue
            if scope is None:
                scope = _proposal_scope(lines, i, m.start() - offs[i])
            hit = [k for k, rx in PROPOSAL_RX if wm_has(scope, rx)]
            where = 'sentence'
            if not hit:
                # Q-703: a command inside a fenced block is labelled by the block's caption.
                cap = _fence_caption(lines, i)
                hit = [k for k, rx in PROPOSAL_RX if wm_has(cap, rx)] if cap else []
                where = 'fence caption'
            if hit:
                # PER-SITE, not per-flag: the same flag proposed in one doc and asserted as
                # runnable in another must still FAIL at the second site.
                proposals.append((d, i + 1, tool, fl, hit[0], where))
                continue
            bad.setdefault((tool, fl), set()).add(d)

if not total:
    print("  [FAIL] zero command-flag uses compared — vacuous, treated as failure.")
    sys.exit(1)

print("  scanned %d docs, %d documented command-flag use(s), %d declared-narration waiver(s),"
      " %d proposal-marker waiver(s), %d flag(s) witnessed ONLY by a source comment"
      % (len(docs), total, waived, len(proposals), len(cited_comment_only)))
for (d, ln, tool, fl, kw, where) in sorted(proposals):
    print("  [prop] %s %s — %s:%d names it as a PROPOSAL (%r in the %s), not as a runnable command"
          % (tool, fl, d, ln, kw, where))
for (tool, fl), ds in sorted(cited_comment_only.items()):
    print("  [FAIL] %s %s — its ONLY quoted occurrence in %s is on a comment line, so the"
          % (tool, fl, TOOLS[tool]))
    print("         \"real flag\" set accepted it on the strength of narration, not code.")
    for d in sorted(ds):
        print("         cited as runnable in %s" % d)

if bad:
    for (tool, fl), ds in sorted(bad.items()):
        print("  [FAIL] %s %s — not a flag of %s" % (tool, fl, TOOLS[tool]))
        for d in sorted(ds):
            print("         cited in %s" % d)
elif cited_comment_only:
    pass                      # already reported above; the [ok] claim must not be printed
else:
    print("  [ok] every documented reproduction command resolves to a real flag whose witness"
          " in the source is code, not a comment")

# --- LEG 2 (REPORT-ONLY, 2026-08-11): a doc that PUBLISHES a measured figure and names no
# way to re-derive it. LEG 1 asks whether a documented command RESOLVES; it can only ask that
# of a doc which documents a command at all. The other half of #213 D is the doc that carries
# the number and no command — the standing rule "never publish a figure ahead of its
# reproduction command" has no instrument at all, and a green LEG 1 is exactly what a corpus
# of pure prose figures produces.
#
# IT IS REPORT-ONLY AND IT MUST STAY THAT WAY. GATE 24's header states the reason for its
# own class and it applies here with more force, not less: auto-discovering FIGURES in prose
# is where false positives live.
#
# THE BLOCKING PREMISE IS ABOUT A FUTURE STATE AND THIS PARAGRAPH ASSERTED IT IN THE PRESENT
# TENSE — corrected 2026-08-11. It read "doc_gates is wired into pre-push as BLOCKING, so a
# false positive does not annoy — it stops a push". VERIFIED false for GATE 25 by reading
# every hook and gate script in the tree that day, not by inference:
#   * `repro-reach` appears in NO hook and in no other script. `grep -rn repro-reach` over
#     scripts/*.sh and .git/hooks/{pre-commit,pre-push} returns hits in doc_gates.sh alone.
#   * scripts/pre_push_gate.sh runs `bash scripts/doc_gates.sh all` (plus a CONDITIONAL
#     `generated` when the pushed range touches roae.py or example/). `all` does not call
#     gate_repro_reach — GATE 25 sits out of it by the caution its own header states, which
#     the `all` banner also prints.
#   * scripts/pre_commit_registry_gate.sh runs only `retract retract-figures ledger-phrases
#     ledger-figures appendonly-head appendonly-history`, and a WARN-only `retract`/
#     `retract-figures` pair on the doc-corpus path.
# 🔴 THAT VERIFICATION WAS TRUE ON 2026-08-11 AND IS NO LONGER TRUE — GATE 25 was promoted into
# `all` on 2026-09-02, so it now runs on every blocking pre-push. The three bullets above are
# KEPT as the dated record of how the exclusion was verified rather than assumed; what changed is
# the third one. LEG 2 is unaffected and that is the point of having settled it early: it cannot
# move the exit code (`sys.exit(1 if bad else 0)`; nothing below touches `bad`), so what promotion
# made blocking is LEG 1 alone. A LEG 2 [note] on a pre-push run is a question, not a finding, and
# the `all` banner now says so in its own text.
#
# THE REASONING IS KEPT BECAUSE IT IS CORRECT ABOUT THE CASE IT WAS WRITTEN FOR. `all` IS
# wired into pre-push as blocking, and GATE 25's header says promotion into `all` is the plan
# once it has been observed silent across a full corpus. On the day that happens, a LEG 2 that
# touched the exit code would stop pushes. Report-only is therefore a property to establish
# NOW, while the gate is cheap to change, rather than a question to reopen at promotion time —
# which is the same argument, stated against the state that actually holds.
# The precedent is gate_revrows, which ends
# `sys.exit(0)  # report-only gate — never blocks`. Nothing below touches `bad`, and the exit
# is taken from LEG 1's verdict alone.
#
# WHAT A "FIGURE" IS HERE, narrowly and by construction. A COMMA-GROUPED INTEGER: a run of
# digits whose comma groups are all exactly three long. That is the shape this project's
# measured counts take (10,525,271,997 records; 1,720,320 orientations) and it is deliberately
# the narrowest defensible reading — percentages, decimals, σ values and ×10ⁿ forms are NOT
# scanned, because each of them appears in ordinary prose orders of magnitude more often. The
# grouping test is done in PYTHON, not in the pattern, so no bounded-repetition quantifier
# enters this file (the `.{0,N}` hang of 2026-08-01, recorded in this file's SAFETY header).
# RE-MEASURED 2026-08-11, AND THE SENTENCE THIS REPLACES WAS FALSE. It read: the loose
# reading "flags 8 docs and THREE of them are list syntax ... the grouped reading drops
# exactly those three". Arithmetic on its own numbers already refused it — 8 - 3 = 5, and the
# gate prints SIX [note] lines — and it named as dropped a file the gate lists by name.
# Both readings were re-run over the same corpus, using LEG 2's own doc list, clearing rules
# and FIG pattern with `_grouped(t)` swapped for `"," in t`:
#   LOOSE ("any comma between digits"):  8 doc(s)
#   GROUPED (this test):                 6 doc(s)
#   DROPPED by the narrowing:            TWO — documentation/GT_LADDER_FORMAT.md (`1,2,3,4,6`
#     and `9,13,16,18,19,21,22,24,25,27,28`) and
#     reports/evidence/f11halfb/PREREGISTRATION_EXTENDED.md (`5,10`). Neither carries a single
#     grouped token, which is why the whole FILE leaves the list.
#   ADDED by the narrowing:              none.
# reports/evidence/f11/RESULTS.md was the third file the old sentence named and it is NOT
# dropped. It carries `0,0`, `0,0,0`, `1,1,0`, `2,0`, `2,2,2` and `63,0` — list syntax, every
# one correctly ignored — AND six real grouped figures, largest 6,076,161. It stays in the
# list and the gate prints it below.
# THE DISTINCTION THE OLD SENTENCE LOST is that the narrowing works TOKEN by token while the
# [note] is per FILE: a file leaves the list only when EVERY comma token in it is list syntax.
# documentation/PARITY_ALTERNATION.md is the same shape one token smaller — `32,16` ignored,
# 601,080,390 and 82,818,450 kept — and it is likewise still reported. So the narrowing is
# doing more work than "drops three files": it discards list syntax in eight files and
# changes the FILE verdict in two of them.
#
# WHAT COUNTS AS A REPRODUCTION COMMAND is DELIBERATELY GENEROUS, for the same reason: a
# [note] should mean "this file offers the reader nothing", not "this file offers something
# my extractor does not recognise". Any ONE of a tool invocation LEG 1 can parse, a fenced
# code block, a backticked scripts/*.sh path, or a mention of tests.py clears the file.
#
# WHAT THIS CANNOT SEE, stated rather than left to be discovered:
#   * IT IS PER-FILE, NOT PER-FIGURE. A doc with fifty figures and one unrelated command is
#     silent here. Per-figure attribution is the part that would need a design pass, and it
#     is precisely the part where false positives would arrive.
#   * A CLEARING COMMAND NEED NOT REPRODUCE THE FIGURE. `tests.py` in a sentence clears a
#     file whose figure came from a 560T enumeration. The claim made is narrow: the file
#     names SOME way in.
#   * IT SAYS NOTHING ABOUT DOCS WITH NO GROUPED INTEGER. A figure written 5×10³¹, 88% or
#     p = 0.849 is outside the scan entirely, so a silent file is not a covered file.
FIG = re.compile(r"[0-9][0-9,]*[0-9]")
REPRO_PATH = re.compile(r"`(?:bash\s+)?scripts/[a-z0-9_./-]+\.sh")

# BUNDLE-LOCAL INSTRUMENTS (added 2026-08-16). reports/evidence/*/ bundles ship the script
# that produced their figures NEXT TO the document -- f11/compute_f11_bf.py,
# r11/r11_phase2_battery.sh, f1/f1_orbit_dp.py. Those files ARE a reproduction path, and
# before this recognizer existed LEG 2 flagged six of them: precisely the failure this
# gate's own header names as the one to avoid, "a [note] should mean 'this file offers the
# reader nothing', not 'this file offers something my extractor does not recognise'".
#
# THE ANTI-GAMING PROPERTY IS EXISTENCE, NOT WORDING. A `**Reproduce:**` directive clears a
# file only when the script it names is REALLY THERE, in the same directory, on disk. Writing
# the sentence is not enough; a renamed or deleted instrument re-flags the file automatically.
# That is deliberately stricter than the four clearing rules above, three of which (a fenced
# block, a tests.py mention, a scripts/*.sh backtick) clear on text alone.
#
# STILL REPORT-ONLY. This widens what counts as cleared; it does not touch the exit code,
# which is taken from LEG 1 alone, per this gate's header.
REPRO_LOCAL = re.compile(r"\*\*Reproduce:?\*\*[^\n]*?`(?:python3?\s+|bash\s+)?"
                         r"([a-z0-9_][a-z0-9_.-]*\.(?:py|sh))`")

def _local_instrument(doc_path, text):
    """A **Reproduce:** directive naming a script that EXISTS beside the document."""
    import os
    d = os.path.dirname(doc_path)
    for m in REPRO_LOCAL.finditer(text):
        if os.path.exists(os.path.join(d, m.group(1))):
            return True
    return False

def _grouped(tok):
    """True for a comma-grouped integer: leading group 1-3 digits, every later group 3."""
    g = tok.split(",")
    if len(g) < 2 or not (1 <= len(g[0]) <= 3):
        return False
    for part in g[1:]:
        if len(part) != 3:
            return False
    return True

naked = []
for d in docs:
    text = open(d, encoding="utf-8", errors="replace").read()
    figs = sorted({t for t in FIG.findall(text) if _grouped(t)}, key=lambda s: (-len(s), s))
    if not figs:
        continue
    # `HEAD_RE` replaced `INV` here 2026-09-03 with finding 13 half A. Both ask the same
    # boolean question — does this doc contain a tool invocation carrying at least one flag —
    # and HEAD_RE is INV's head with the flag run moved into a lookahead, so the match SET is
    # identical. Measured: LEG 2's doc counts are unchanged. (Caught by READING the output: the
    # first cut of half A deleted INV and left this line, and LEG 2 printed a NameError
    # traceback while LEG 1 printed its [ok] — a gate whose interpreter fails mid-run.)
    if (HEAD_RE.search(text) or "```" in text or REPRO_PATH.search(text)
            or "tests.py" in text or _local_instrument(d, text)):
        continue
    naked.append((d, figs))

print("  -- LEG 2 (REPORT-ONLY): a published figure whose file names no way to re-derive it --")
print("  [note] LEG 2 read %d doc(s); %d publish a comma-grouped figure and carry no tool"
      " invocation, no fenced block, no scripts/*.sh path, no tests.py mention and no"
      " **Reproduce:** directive naming a script that exists beside them"
      % (len(docs), len(naked)))
for d, figs in naked:
    print("  [note] %s — %d figure(s), largest %s" % (d, len(figs), figs[0]))
print("         (report-only: LEG 2 NEVER affects the exit code and is NOT covered by any")
print("          PASS verdict. A [note] is a QUESTION — 'can a reader re-derive this?' — not")
print("          a finding; an index or a narrative may legitimately carry a figure whose")
print("          reproduction lives in the report it links to.)")

# `cited_comment_only` joins `bad` in the exit code (finding 13 half B). It is kept as its own
# name rather than folded into `bad` so the two FAILs read differently: `bad` is "no such flag",
# this is "the flag's only witness is narration". LEG 2 still cannot move the exit code.
sys.exit(1 if (bad or cited_comment_only) else 0)
PY
  } | DOC_GATES_DOCS="$DOCS" python3 -
  local rc=$?
  if [ "$rc" != "0" ]; then
    echo "  A published figure whose reproduction command errors is not reproducible."
    echo "  GATE 2 cannot see this: it reports flags in CODE that are undocumented,"
    echo "  never a DOC naming a flag that does not exist."
    echo "  Fix the doc, or declare the flag as narration with a stated reason."
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# GATE 26 — a count labelled CANONICAL may not exceed its own factorial ceiling.
#
# WHY THIS GATE AND NOT ANOTHER SWEEP. The "≈3×10³⁷ distinct canonical orderings" figure was
# withdrawn on 2026-08-24 by enumerating nineteen sites that matched the STRING. Four days later,
# building this gate found the same figure still live at five more (`enumeration/LEADERBOARD.md:3@db4ac3dc`
# and `:170@db4ac3dc`, `documentation/SOLVE_SUMMARY.md:178@db4ac3dc` and `:211`, `documentation/CITATIONS.md:97@db4ac3dc`) and
# the same DEFECT live at five per-branch sites written as `10³⁶`. None of the ten matched a search
# for `3.3×10³⁷`, because a decomposition (`10³⁶` per branch), a restatement ("valid arrangements")
# and a hyphenation (`distinct-canonical`) are not the string. A sweep keyed on a figure cannot find
# that figure's rewordings; only a check keyed on the PROPERTY can.
#
# THE PROPERTY, and it needs no estimate to state. The deduplicated object is a PAIR ORDERING. C4
# pins pair 1, leaving 31 to order, so there are at most 31! ≈ 8.2228×10³³ canonical orderings in
# the whole space — and every canonical count published here is a count of a subset of that set.
# So: a figure labelled canonical whose magnitude exceeds 31! is wrong on arithmetic alone, with no
# estimator, sampling argument or distributional assumption involved.
#
# 🔴 THE CEILING IS DERIVED HERE, NOT READ FROM A DOCUMENT. log10(31!) is summed in the gate. If it
# were grepped out of CORRECTIONS.md the gate would be checking the corpus against itself, and a
# wrong ceiling in the doc would license the very figures it is supposed to refuse — the
# verifier-closure defect this suite keeps finding. An INDEPENDENT derivation is the whole point.
#
# 🔴 WHY THE BINDING IS TIGHT AND MEASURED. The first cut required only that "canonical" appear
# somewhere on the LINE. Measured against the corpus: 68 hits, essentially all false — raw figures
# (1.3287×10³⁸ raw C1–C5, 1.097051×10³⁹ complete C1/C2/C4/C5) sitting on lines that mention the word
# elsewhere. Both are correctly above 31!, because the RAW ceiling is 31!·2³¹ ≈ 1.77×10⁴³. A gate
# firing on 68 sites reports nothing — the always-fires failure that has killed audits here before.
# Requiring "canonical" within 40 characters of the figure, and no "raw" in that same window, takes
# it to the real defects and their quotations.
#
# EXCLUSIONS, each with its reason, because an unexplained exclusion is a hole:
#   * a window naming `30!`/`31!` or "ceiling" — that is the ceiling STATEMENT, not a claim.
#   * a line already carrying WITHDRAWN or LABEL CORRECTED — marked is the cured state.
#   * "canonical-leaf" / "canonical tree" — TR-10 uses these for leaves OF the canonical search
#     tree, i.e. RAW C1–C5 leaves, not deduplicated orderings. Its 1.3275×10³⁸ is the raw estimate
#     and is correct. That the same word carries both senses in this corpus is a real terminology
#     hazard; it is recorded rather than enforced here, because this gate must not adjudicate it.
#   * `documentation/CORRECTIONS.md` figures inside a `code span` — the ledger's job is to quote the
#     figure it withdraws, and GATE 10a makes it append-only, so it could not be edited even if the
#     quotation were wrong.
#
# ---------------------------------------------------------------------------------------------
# LEG 2 (2026-09-02) — THE SAME PROPERTY, IN ASCII SCIENTIFIC NOTATION.
#
# 🔴 THE DEFECT THIS LEG EXISTS FOR IS THE NOTATION, NOT THE ARITHMETIC. Measured before it was
# written, by planting ONE claim twice in `documentation/PROJECT_OVERVIEW.md`:
#     "about 3.3×10³⁷ distinct canonical orderings"  -> GATE 26 FAILS  (rc 1)
#     "about 3.3e37 distinct canonical orderings"    -> GATE 26 PASSES (rc 0)
# Identical claim, identical magnitude, identical window. LEG 1's pattern requires the Unicode
# superscript form, so a figure typed the way the solver PRINTS it — `est=1.328702e38` — walked
# through a gate built to refuse exactly that figure. A gate that can be evaded by changing the
# keyboard is not checking the property it says it checks.
#
# 🔴 WHY NOT THE REGEX THAT WAS PRESCRIBED. The adjudicated form was the bare
# `\d(?:\.\d+)?[eE]\+?\d+`. It was PLANT-TESTED BEFORE BEING ADOPTED, and it is unusable:
# run over the corpus (at fcd9feab) with every one of LEG 1's other filters applied, it fires on EIGHT sha256
# fragments in five files and on nothing else —
#   documentation/HISTORY.md:2014@fcd9feab (`…df2495e7999315afc…` -> 5e7999315),  :2268, :4784, :4786, :4808,
#   documentation/PERFORMANCE_HISTORY.md:424@fcd9feab (`2cc966e48399841e…` -> 6e48399841),
#   documentation/PROJECT_OVERVIEW.md:109@fcd9feab, runs/20260419_100T_d3_d128westus3/README.md:3@fcd9feab
# — because a hex digest contains `e` between digits, and `9a968fa21f74e36ad…` therefore reads as
# 4×10³⁶. Eight false positives and zero true ones is the always-fires failure this gate's own
# charter (above) was written to refuse; it would be switched off within a day.
#
# THE TWO GUARDS, AND WHAT EACH IS INDEPENDENTLY WORTH — MEASURED, NOT ASSERTED:
#   (a) hex-context lookarounds `(?<![0-9a-fA-F.])…(?![0-9a-fA-F])`. Corpus-wide they cut the
#       candidate set from 628 raw matches to 181, and on their own they suppress all eight of the
#       sha fragments above.
#   (b) the code-span skip, which LEG 1 grants only to CORRECTIONS.md, applied HERE to every file.
#       On its own it ALSO suppresses all eight, because all eight are inside backticks.
# So on today's corpus either guard alone would do, and that is exactly why BOTH ship: (b) covers a
# digest quoted as `code`, (a) covers one written bare in prose, and each is a real shape.
#
# 🔴 THE RECORD, RUN 2026-09-02 ON A 91-FILE COPY OF THIS CORPUS. Every line below is measured
# output, not a description of what the code should do. Reproduce it by appending the quoted line
# to `documentation/PROJECT_OVERVIEW.md` and running `scripts/doc_gates.sh canonical-ceiling`.
#
#   PRE-FIX BASELINE, this leg absent — the defect and the notation separated:
#     "about 3.3×10³⁷ distinct canonical orderings"  -> [FAIL] ... log10=37.52 exceeds ...   rc 1
#     "about 3.3e37 distinct canonical orderings"    -> [ok] every canonical-labelled ...     rc 0
#   RED, this leg present:
#     "about 3.3e37 distinct canonical orderings"           -> [FAIL] '3.3e37' ... rc 1
#     "the canonical count is est=1.328702e38 for the ..."  -> [FAIL] '1.328702e38' ... rc 1
#   NEGATIVE CONTROLS, this leg present — silence, and silence for the stated reason:
#     "the raw canonical-tree leaf estimate is est=1.328702e38"      -> rc 0 (the raw carve-out)
#     "560T canonical sha 9a968fa21f74e36a…" written BARE            -> rc 0, hex census 447->449
#     "the canonical layer prints `leaves_canonical : est=1.328702e38`" -> rc 0, span census 0->1
#   Each control moves the census counter that names its own guard, so the silence is attributed
#   rather than assumed.
#
#   MUTANTS — each removes exactly ONE defence from a copy of this script and is then shown to be
#   caught by the case that defence was holding. A red test proves the checker fires on a case
#   that was thought of; a mutant proves it fires on one deliberately hidden from it.
#     MUTANT A  hex-context lookarounds deleted (i.e. the PRESCRIBED regex adopted verbatim)
#               -> fires on the BARE sha control: [FAIL] '4e36' is labelled CANONICAL, log10=36.60
#               real gate on the same input: rc 0.   Guard (a) is load-bearing.
#     MUTANT B  the all-files code-span skip deleted, nothing else
#               -> fires on the quoted-output control: [FAIL] '1.328702e38' ... log10=38.12
#               real gate on the same input: rc 0.   Guard (b) is load-bearing.
#     MUTANT C  the LEG 2 pattern made unmatchable
#               -> [FAIL] GATE 26 LEG 2 matched ZERO ... candidates, rc 1.  The dead-leg check
#               ERRORS instead of passing, which is the whole point of it.
#   Corpus-wide regression: `doc_gates.sh all` before and after this leg differ by exactly the
#   three LEG 2 census lines — no finding gained, and none suppressed.
#
# ⚠ OWED: a permanent `--selftest` fire-proof pair for this leg. It is NOT written here because it
#   could not be run — `--selftest` reverts the whole tree with `git checkout -- .`, and this leg
#   landed during a long no-commit window with other lanes' uncommitted work in the tree. An
#   assertion that has never been executed is the no-op-assertion shape this suite keeps finding,
#   and shipping one blind would be worse than the transcript above. Write it, and RUN it, on a
#   clean committed tree.
#
# WHY THE CODE-SPAN SKIP IS WIDER HERE THAN IN LEG 1, and why that is not a hole. In this corpus
# ASCII scientific notation is the SOLVER'S OUTPUT FORMAT — `est=1.328702e38  95%CI=[…]`. It
# appears inside backticks because it is a transcript of what a tool printed, and a transcript is
# evidence, not a claim; prose claims here are written in the superscript form, which LEG 1 still
# covers with CORRECTIONS.md as its only exemption. The skip is therefore scoped to the notation
# that only ever appears as quoted output — and it is AUDITED rather than trusted: the gate prints
# how many candidates each guard suppressed, so the exemption cannot grow in silence.
#
# 🔴 A LEG THAT SCANS NOTHING HAS CLEARED NOTHING. If the ASCII pattern matches zero candidates
# anywhere in the corpus, this leg FAILS instead of passing. Reaching that state means either the
# corpus lost every scientific-notation figure it has, or the pattern broke — and neither of those
# is a clean tree. The same reasoning as the EMPTY-corpus check below.
#
# 🔴 DO NOT "SIMPLIFY" EITHER GUARD BACK OUT. The prescribed one-liner is shorter and it is wrong;
# the eight sites and the two mutants above are the record of why.
# ---------------------------------------------------------------------------------------------
gate_canonical_ceiling() {
  echo "== GATE 26: no count labelled CANONICAL may exceed its own factorial ceiling =="
  local out rc=0
  out=$(printf '%s\n' "$DOCS" | python3 -c "$(_md_num_prelude)"'
import sys, io, re, math
SUP={"⁰":"0","¹":"1","²":"2","³":"3","⁴":"4","⁵":"5","⁶":"6","⁷":"7","⁸":"8","⁹":"9"}
NEG="⁻"
CEIL=sum(math.log10(k) for k in range(1,32))          # log10(31!), derived HERE
# Q-968 (A08#5, the one-digit mantissa): the mantissa was `\d(?:[.,]\d+)?`, ONE integer digit, so
# "12×10³³" was read as 2×10³³ and "12e33" was not read at all. Both legs now take the shared
# lexer'"'"'s mantissa (any digit run, comma groups, a decimal) at its left edge.
pat=re.compile(r"(" + MD_EDGE + r"(?:\d{1,3}(?:,\d{3})+|\d+)(?!\d)(?:\.\d+)?)\s*[×x]\s*10([" + "".join(SUP) + NEG + r"]+)")
# LEG 2. The lookarounds are the whole difference between a gate and a sha-fragment siren.
sci=re.compile(r"(?<![0-9a-fA-F.])(\d+(?:\.\d+)?)[eE]\+?(\d+)(?![0-9a-fA-F])")
lax=re.compile(r"\d+(?:\.\d+)?[eE]\+?\d+")   # the PRESCRIBED form, kept only to size guard (a); Q-968: same mantissa as sci
span=re.compile(r"`[^`]*`")
# Q-937 (batch 35): the LEDGER ANCHOR, as GATE 27 reads it (the header there has the rules), but
# per LINE: a match is also exempt when the same line links a CX entry of documentation/CORRECTIONS.md
# whose own text quotes the matched figure exactly as written. The marker words below exempt a line
# whatever figure it states; the anchor exempts one figure, and only the one its entry records.
import os
LEDGER="documentation/CORRECTIONS.md"
LINK=re.compile(r"\[([^\]\n]*)\]\(([^)\s]*CORRECTIONS\.md)(#[^)\s]*)?\)")
def ledger_entries():
    ent={}; cur=None; lvl=0; fence=False
    try: src=io.open(LEDGER,encoding="utf-8").read().split("\n")
    except OSError: return ent
    for l in src:
        if l.lstrip().startswith("```"): fence=not fence
        h=None if fence else re.match(r"(#{1,6})\s+(.*)",l)
        if h and (cur is None or len(h.group(1))<=lvl):
            m=re.match(r"CX-(\d+)\b",h.group(2)); cur=None
            if m: cur=int(m.group(1)); lvl=len(h.group(1)); ent[cur]=[]
            continue
        if cur is not None: ent[cur].append(l)
    return {k:"\n".join(v) for k,v in ent.items()}
ENT=ledger_entries()
def anchored(f,text):
    out=[]
    for m in LINK.finditer(text):
        if os.path.normpath(os.path.join(os.path.dirname(f),m.group(2)))!=LEDGER: continue
        cx=re.search(r"\bCX-(\d+)\b",m.group(1)) or re.match(r"#cx-(\d+)\b",(m.group(3) or "").lower())
        if cx and int(cx.group(1)) in ENT: out.append(ENT[int(cx.group(1))])
    return out
files=[l.strip() for l in sys.stdin if l.strip()]
if not files:
    print("EMPTY"); sys.exit(0)
n=0; sci_cand=0; sci_hex=0; sci_span=0
for f in files:
    try: lines=io.open(f,encoding="utf-8").read().splitlines()
    except OSError as e:
        print("READFAIL\t%s\t%s" % (f,e)); n+=1; continue
    for ln,line in enumerate(lines,1):
        if "WITHDRAWN" in line or "LABEL CORRECTED" in line: continue
        anc=anchored(f,line) if "CORRECTIONS.md" in line else []
        low=line.lower()
        spans=[(m.start(),m.end()) for m in span.finditer(line)]
        for m in pat.finditer(line):
            if NEG in m.group(2): continue
            try:
                v=math.log10(float(m.group(1).replace(",","")))+int("".join(SUP[c] for c in m.group(2)))
            except (ValueError,KeyError): continue
            if v<=CEIL+0.01: continue
            w=low[max(0,m.start()-40):m.end()+40]
            if "canonical" not in w: continue
            if "raw" in w: continue
            if re.search(r"3[01]!|ceiling", w): continue
            if "canonical-leaf" in w or "canonical tree" in w: continue
            if f=="documentation/CORRECTIONS.md" and any(a<=m.start() and m.end()<=b for a,b in spans): continue
            if any(m.group(0) in e for e in anc): continue
            n+=1
            print("HIT\t%s\t%d\t%s\t%.2f\t%s" % (f,ln,m.group(0),v,line[max(0,m.start()-60):m.end()+60].strip()[:150]))
        # ---- LEG 2: the same property written the way the solver prints it ----
        sci_cand+=len(sci.findall(line))
        sci_hex+=len(lax.findall(line))-len(sci.findall(line))
        for m in sci.finditer(line):
            try:
                v=math.log10(float(m.group(1)))+int(m.group(2))
            except (ValueError,OverflowError): continue
            if v<=CEIL+0.01: continue
            w=low[max(0,m.start()-40):m.end()+40]
            if "canonical" not in w: continue
            if "raw" in w: continue
            if re.search(r"3[01]!|ceiling",w): continue
            if "canonical-leaf" in w or "canonical tree" in w: continue
            # code-span skip, ALL files. Reason in the LEG 2 header block. Counted, never silent.
            # Q-965 (A08#6): only a span that QUOTES OUTPUT is exempt. A span holding nothing but the
            # figure ("There are `3.3e37` canonical orderings.") is a claim set in code font, not a
            # transcript, and it passed; it is now judged like the bare figure.
            if any(a<=m.start() and m.end()<=b and not re.fullmatch(r"[~≈]?\s*"+re.escape(m.group(0)), line[a+1:b-1].strip()) for a,b in spans):
                sci_span+=1; continue
            if any(m.group(0) in e for e in anc): continue
            n+=1
            print("HIT\t%s\t%d\t%s\t%.2f\t%s" % (f,ln,m.group(0),v,line[max(0,m.start()-60):m.end()+60].strip()[:150]))
print("SCI\t%d\t%d\t%d" % (sci_cand,sci_hex,sci_span))
print("CEIL\t%.6f" % CEIL)
') || { echo "  [FAIL] GATE 26 could not run its scanner — NOTHING was checked."; return 1; }
  if grep -qx 'EMPTY' <<<"$out"; then
    echo "  [FAIL] the markdown corpus reached this gate EMPTY — nothing was checked."
    return 1
  fi
  local ceil; ceil=$(printf '%s\n' "$out" | awk -F'\t' '$1=="CEIL"{print $2}')
  # LEG 2's census. A leg that matched nothing corpus-wide is not a leg that cleared the corpus.
  local sci_cand sci_hex sci_span
  sci_cand=$(printf '%s\n' "$out" | awk -F'\t' '$1=="SCI"{print $2}')
  sci_hex=$(printf '%s\n' "$out" | awk -F'\t' '$1=="SCI"{print $3}')
  sci_span=$(printf '%s\n' "$out" | awk -F'\t' '$1=="SCI"{print $4}')
  if ! grep -qxE '[0-9]+' <<<"$sci_cand"; then
    echo "  [FAIL] GATE 26 LEG 2 printed no census line — the ASCII scientific-notation leg did not"
    echo "         run, so nothing it is responsible for was checked."
    return 1
  fi
  if [ "$sci_cand" -eq 0 ]; then
    echo "  [FAIL] GATE 26 LEG 2 matched ZERO scientific-notation candidates in the whole corpus."
    echo "         Either the corpus lost every 'NeNN' figure it has, or the pattern broke. A leg"
    echo "         that scans nothing has cleared nothing, so this is a finding, not a pass."
    return 1
  fi
  while IFS=$'\t' read -r tag f ln fig v ctx; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f:$ln  '$fig' is labelled CANONICAL but log10=$v exceeds log10(31!)=$ceil"
    echo "         … $ctx"
    rc=1
  done < <(printf '%s\n' "$out")
  while IFS=$'\t' read -r tag f err; do
    [ "$tag" = READFAIL ] || continue
    echo "  [FAIL] $f could not be read ($err) — a file this gate cannot read is not a file it cleared."
    rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         A canonical count is a count of pair orderings. C4 pins pair 1, leaving 31 to order,"
    echo "         so at most 31! ≈ 8.2228×10³³ exist. Either the figure is RAW and mislabelled (say raw,"
    echo "         and check it against 31!·2³¹ ≈ 1.77×10⁴³), or it is withdrawn. See CORRECTIONS.md 2026-08-28."
    return 1
  fi
  echo "  [ok] every canonical-labelled magnitude sits under log10(31!)=$ceil (ceiling derived in-gate)"
  echo "  [ok] LEG 2 (ASCII 'NeNN'): $sci_cand candidates examined; $sci_hex suppressed as hex/sha"
  echo "       fragments by the hex-context guard; $sci_span suppressed as quoted output inside a"
  echo "       code span. Both suppression counts are printed so neither exemption can grow unseen."
  return 0
}

# ---------------------------------------------------------------------------
# GATE 27 — a line restating a WITHDRAWN figure must carry a supersession marker.
#
# WHY THIS EXISTS AND WHY IT IS NOT GATE 3b. GATE 3b demands a content-anchored allowlist row
# for EVERY occurrence ("no auto-exemption"), which is right for a statistic with a handful of
# mentions. It does not scale to the project's LARGEST withdrawals: "3×10³⁷" alone occurs 40
# times across 14 files, nearly all legitimate prose that already carries a marker. Registering
# it in 3b would need ~40 hand-anchored rows — which is precisely why the headline 2026-08-24
# withdrawal was NEVER registered anywhere, leaving the biggest retraction in the project
# unguarded (Q-342).
#
# 🔴 MEASURED, NOT HYPOTHETICAL. Merging origin/v4-query-program restores
# enumeration/LEADERBOARD.md lines 3 and 170, which state ≈3×10³⁷ with NO marker, silently
# undoing commit b8d45b5e. Verified 2026-08-28 by copying the branch file over the corrected
# one: `doc_gates retract-figures` PASSED and `doc_gates canonical-ceiling` PASSED. A 201-hunk
# merge whose acceptance harness cannot see a reverted correction is worse than no merge.
#
# The rule is deliberately WEAKER than 3b's: it cannot judge whether a marker is apt, only that
# some supersession word is on the line. That is the case a merge regression produces — a
# reintroduced figure with no marker at all.
#
# documentation/CORRECTIONS.md is EXEMPT, and this is the only exemption. It is the ledger of
# record: quoting a withdrawn figure is its job, all 12 of its unmarked lines do exactly that,
# and GATE 10a makes it append-only so it cannot be quietly rewritten.
#
# THE LEDGER ANCHOR (Q-937, batch 35). Inline markers are to MOVE into CORRECTIONS.md (Q-634 Part 1,
# Q-938). Keyed only on marker words, this gate would let a marker move only together with every
# figure it sits beside, so a block is ALSO accepted for a figure F when it links a ledger entry
# by its CX id -- `[CORRECTIONS CX-<n>](<path to documentation/CORRECTIONS.md>)`, or a `#cx-<n>`
# fragment -- AND that entry's own text quotes F. Three things must hold, each checked: the link
# resolves to documentation/CORRECTIONS.md from the citing file; a `CX-<n>` heading exists there
# (headings inside code fences do not count); and the entry under it, up to the next heading of the
# same or a higher level, contains F as a plain substring. A link to the ledger with no CX id, to
# an entry that does not quote F, or to an id the ledger lacks exempts nothing. The anchor is
# stable because the ledger is append-only (GATE 10a): moving the marker into its CX entry keeps
# the figure quoted there. GATE 26 reads the same anchor, on the line. Mutants: tests.py
# TestQ937LedgerAnchoredGates.
gate_withdrawn_markers() {
  echo "== GATE 27: withdrawn figures are never restated without a supersession marker =="
  local REG=documentation/WITHDRAWN_FIGURES.tsv
  require_rows "$REG" "A withdrawn figure that nothing registers is a figure nobody re-checks." || return 1
  local out
  out=$(printf '%s\n' "$DOCS" | python3 -c "$(_md_norm_prelude; _wm_prelude)"'
import sys, io, re
REG="documentation/WITHDRAWN_FIGURES.tsv"
EXEMPT={"documentation/CORRECTIONS.md"}
MARK=wm_re(r"withdrawn|label\s+corrected|corrected\s+20\d\d|scoped\s+20\d\d|superseded|retract\w*|run\s+description\s+corrected")  # Q-966 (A08#11): whole words via the shared matcher, and a NEGATED marker is none -- "remains unretracted", "not superseded" exempted before.  # \\s+ not " ": a marker wrapping as "[CORRECTED\\n2026-08-28" is the normal case in this corpus and a literal space missed every one of them
import os
LEDGER="documentation/CORRECTIONS.md"
LINK=re.compile(r"\[([^\]\n]*)\]\(([^)\s]*CORRECTIONS\.md)(#[^)\s]*)?\)")
def ledger_entries():
    ent={}; cur=None; lvl=0; fence=False
    try: src=io.open(LEDGER,encoding="utf-8").read().split("\n")
    except OSError: return ent
    for l in src:
        if l.lstrip().startswith("```"): fence=not fence
        h=None if fence else re.match(r"(#{1,6})\s+(.*)",l)
        if h and (cur is None or len(h.group(1))<=lvl):
            m=re.match(r"CX-(\d+)\b",h.group(2)); cur=None
            if m: cur=int(m.group(1)); lvl=len(h.group(1)); ent[cur]=[]
            continue
        if cur is not None: ent[cur].append(l)
    return {k:"\n".join(v) for k,v in ent.items()}
ENT=ledger_entries()
def anchored(f,text):
    out=[]
    for m in LINK.finditer(text):
        if os.path.normpath(os.path.join(os.path.dirname(f),m.group(2)))!=LEDGER: continue
        cx=re.search(r"\bCX-(\d+)\b",m.group(1)) or re.match(r"#cx-(\d+)\b",(m.group(3) or "").lower())
        if cx and int(cx.group(1)) in ENT: out.append(ENTN.setdefault(int(cx.group(1)), md_inline(ENT[int(cx.group(1))])))
    return out
ENTN={}
def bare(fig,text,anc):
    return fig in text and not any(fig in e for e in anc)
figs=[]
for ln in io.open(REG,encoding="utf-8"):
    c=ln.rstrip("\n").split("\t")  # Q-773: comment = col 1 exactly "#" or "# ..." (reg_row_kind); a figure "#7..." is DATA
    if not ln.strip() or c[0]=="#" or c[0].startswith("# "): print("HASHROW\t%s"%c[0]) if any(x and not (x[:1]=="<" and x[-1:]==">") for x in c[1:]) else None; continue  # Q-761: a "# " line with data columns is LOUD, as in GATE 3/11
    if len(c)>=2 and c[0].strip() and c[1].strip(): figs.append((md_inline(c[0]),c[1]))
    else: print("MALFORMED\t%s"%ln.rstrip("\n")[:100])  # Q-969 (A08#8): a figure with no "why" column was DROPPED while require_rows counted it
print("ACCEPTED\t%d"%len(figs))
if not figs: print("NOFIGS"); sys.exit(0)
files=[l.strip() for l in sys.stdin if l.strip()]
if not files: print("EMPTY"); sys.exit(0)
n=0; nfiles=0; pop_rows=0; pop_blocks=0
for f in files:
    if f in EXEMPT: continue
    nfiles+=1
    try: lines=md_text(io.open(f,encoding="utf-8").read()).split("\n")
    except OSError as e: print("READFAIL\t%s\t%s"%(f,e)); n+=1; continue
    # Q-965 (A08#9, A08#10): figures and markers are matched on md_inline text (a figure wrapped as
    # "null P =\n0.034", or set in emphasis, is the figure), both sides folded alike; and a table row
    # is any row the shared normaliser sees -- a GFM table without edge pipes, or one indented, was
    # read as PROSE before, where a marker on another row exempted it.
    _L, KIND, _b, _u = md_parse("\n".join(lines))
    # 🔴 PARAGRAPH WINDOW, not a single line. Measured 2026-08-28 while building this gate: a
    # line-level rule flagged reports/TR4:72 and DISTRIBUTIONAL_ANALYSIS.md:587, both of which
    # ARE correctly marked -- TR4 carries the figures on one line and its marker on the next
    # (wrapped prose), and DISTRIBUTIONAL holds "null P = 0.034" INSIDE the quoted text of its own
    # correction marker. Flagging correctly-marked prose is the always-fires failure that gets a
    # gate ignored. A reader sees the paragraph, so the gate reads the paragraph: blank-line
    # delimited, which is how markdown blocks are actually bounded.
    para=[]; start=[]; cur=[]; cs=1
    for i,line in enumerate(lines,1):
        if line.strip()=="":
            if cur: para.append("\n".join(cur)); start.append(cs)
            cur=[]; cs=i+1
        else: cur.append(line)
    if cur: para.append("\n".join(cur)); start.append(cs)
    # V-3 (Codex V2-04 #4, root R10 guarantee-granularity mismatch, 2026-09-02): the paragraph
    # window is right for WRAPPED PROSE and wrong for TABLES. A table row is a self-contained
    # claim -- a reader takes "| headline | 3x10^37 |" at face value whether or not some OTHER
    # row of the same table says "corrected 2026-08-28". Measured before this change: an
    # unmarked withdrawn figure in a table row whose neighbouring row carried a marker passed
    # rc=0 while the same row in a marker-free block failed rc=1. So: table rows (lines that
    # begin with "|") are judged PER ROW; everything else keeps the paragraph window. The [ok]
    # sentence below states exactly that split, so the guarantee and the scan agree.
    for blk,bs in zip(para,start):
        blines=blk.split("\n")
        isrow=lambda j: KIND[bs-1+j] in ("thead","tdelim","trow")
        rows=[(j,md_inline(l)) for j,l in enumerate(blines) if isrow(j)]
        prose=[(j,md_inline(l)) for j,l in enumerate(blines) if not isrow(j)]
        # POPULATION, counted before any marker test: how many rows / prose blocks state a
        # registered figure at all. Printed, and a zero fails -- the registry names figures
        # with ~40 known occurrences, so a scan that matched none of them is a broken scan.
        pop_rows+=sum(1 for j,l in rows if any(fig in l for fig,why in figs))
        if prose and any(fig in " ".join(l for j,l in prose) for fig,why in figs): pop_blocks+=1
        hit=False
        for j,l in rows:
            if wm_has(l,MARK): continue
            anc=anchored(f,blines[j])
            for fig,why in figs:
                if bare(fig,l,anc):
                    print("HIT\t%s\t%d\t%s\t%s"%(f,bs+j,fig,l.strip()[:120])); n+=1; hit=True; break
            if hit: break
        if hit: continue
        ptext=" ".join(l for j,l in prose)
        if not prose or wm_has(ptext,MARK): continue
        anc=anchored(f,"\n".join(blines[j] for j,l in prose))
        for fig,why in figs:
            if bare(fig,ptext,anc):
                off=next((j for j,l in prose if fig in l),None)
                if off is None:   # the figure spans a wrap: name the line it starts on
                    p=ptext.find(fig); acc=0
                    for j,l in prose:
                        acc+=len(l)+1
                        if acc>p: off=j; break
                bad_line=blines[off].strip()[:120]
                print("HIT\t%s\t%d\t%s\t%s"%(f,bs+off,fig,bad_line)); n+=1; break
print("POP\t%d\t%d\t%d"%(nfiles,pop_rows,pop_blocks))
print("LEDGER\t%d"%len(ENT))
print("COUNT\t%d"%n)
') || { echo "  [FAIL] GATE 27 scanner failed — NOTHING was checked."; return 1; }
  grep -qx 'EMPTY' <<<"$out" && { echo "  [FAIL] corpus reached GATE 27 empty."; return 1; }
  grep -qx 'NOFIGS' <<<"$out" && { echo "  [FAIL] $REG parsed to zero figures."; return 1; }
  local _mal; _mal=$(printf '%s\n' "$out" | awk -F'\t' '$1=="MALFORMED"{print "         " $2}')
  [ -n "$_mal" ] && { echo "  [FAIL] Q-969: $REG has row(s) that are not \"figure<TAB>why\", so they are not checked:"; printf '%s\n' "$_mal"; return 1; }
  reg_accepted_check "$REG" "$(printf '%s\n' "$out" | awk -F'\t' '$1=="ACCEPTED"{print $2; exit}')" "GATE 27" || return 1
  local pf pr pb
  IFS=$'\t' read -r pf pr pb < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pr:-}" || ! grep -qxE '[0-9]+' <<<"${pb:-}"; then
    echo "  [FAIL] GATE 27 printed no population census — the scan did not complete, so nothing it"
    echo "         is responsible for was checked."
    return 1
  fi
  if [ $((pr+pb)) -eq 0 ]; then
    echo "  [FAIL] GATE 27 found ZERO table rows and ZERO prose blocks stating ANY registered withdrawn"
    echo "         figure across $pf files. The registry names figures with dozens of known occurrences,"
    echo "         so a scan that matched none of them is a broken scan, not a clean corpus."
    return 1
  fi
  local rc=0 hrc=0
  while IFS=$'\t' read -r tag f ln fig line; do
    [ "$tag" = HASHROW ] && { echo "  [FAIL] Q-761: $REG line \"$f\" is comment-shaped (\"# ...\") but carries data column(s), so it is not checked. Register the figure without the leading \"# \"."; hrc=1; continue; }; [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f:$ln restates withdrawn figure '$fig' with NO supersession marker and no ledger anchor quoting it"
    echo "         $line"
    rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         A merge or edit that reintroduces a withdrawn figure unmarked is the exact"
    echo "         regression this gate exists for. Add the marker, link the CX entry that quotes the"
    echo "         figure ([CORRECTIONS CX-<n>](…/CORRECTIONS.md)), or withdraw the line."
    return 1
  fi; [ "$hrc" -eq 0 ] || return 1
  echo "  [ok] every TABLE ROW (judged per row) and every PROSE PARAGRAPH (judged as a block, so a"
  echo "       marker on the wrapped next line counts) that states a registered withdrawn figure"
  echo "       carries a supersession marker, or links a ledger entry (CX id) that quotes the figure —"
  echo "       population: $pf files scanned, $pr figure-bearing table rows and $pb figure-bearing prose"
  echo "       blocks judged; $(printf '%s\n' "$out" | awk -F'\t' '$1=="LEDGER"{print $2; exit}') CX entries readable as anchors"
  return 0
}

gate_framing_era() {
  echo "== GATE 28: a published sha256sum recipe that ignores the gz-framing era =="
  # Q-346. DEPLOYMENT.md:910@cbf818c4 published `sha256sum -c sub_<branch>.sha256` as THE archive
  # verification recipe. Since #169 (d8671550, 2026-06-17) shards are gz-framed by default and
  # the .sha256 sidecar holds the LOGICAL (decompressed) sha, so that command hashes the gzip
  # CONTAINER and prints FAILED on a byte-correct artifact. Measured 2026-08-29 with the shipped
  # binary on a fresh --sub-branch run: sidecar 4cd43b2b…, container 6e4d49b8…, `sha256sum -c`
  # rc=1 "FAILED", `gzip -dc | sha256sum` exact. A reader following the published recipe
  # concludes the archive is corrupt. That is the phantom-drift direction the Q-324 commit
  # itself calls the expensive kind.
  #
  # 🔴 WHY IT DOES NOT GREP FOR THE FIX'S OWN WORDING, which was the obvious design and is the
  # implementation-shaped one. This gate derives its population from the corpus: every place a
  # sha256sum recipe is actually PUBLISHED. The fix text is not privileged — a differently
  # worded but genuinely era-qualified recipe passes, and my exact sentences with the era note
  # deleted FAIL. What it requires is that the era is DISAMBIGUATED near the command, by any of
  # the vocabulary the corpus already uses for it (#169 / SOLVE_COMPRESS=0 / gzip -dc / 1f 8b).
  #
  # 🔴 AND IT IS NOT SATISFIED BY ITS OWN EMPTINESS. If every `sha256sum -c` disappeared from
  # the corpus this would pass vacuously while measuring nothing, which is the closure defect
  # Codex N07 named: a verifier must be FALSE when its target is absent. So a population floor
  # is asserted first, and a collapse is an ERROR, not a pass.
  #
  # 🔴 THE FLOOR COUNTS FILES, NOT MATCHING LINES, and that distinction was measured rather
  # than guessed. The pre-fix corpus held exactly 2 recipe LINES in 2 files; the fix's own
  # explanatory prose names `sha256sum -c` twice more, taking the line count to 4. A line
  # floor of 2 would therefore have become satisfiable BY THE FIX'S OWN COMMENTARY — both
  # real recipes could be deleted and the gate would still report a healthy population, which
  # is the closure defect one level up. The file count is 2 before the fix and 2 after, so it
  # tracks the subject instead of the fix.
  local FLOOR=2
  local out
  out=$(python3 - "$FLOOR" <<'PY'
import re, subprocess, sys, os
floor = int(sys.argv[1])
# Population: tracked markdown only. Untracked scratch files are not published.
files = subprocess.run(["git","ls-files","*.md"], capture_output=True, text=True).stdout.split()
if not files:
    print("ERROR\tgit ls-files returned no markdown at all"); raise SystemExit(0)
# A RECIPE, not a mention: `sha256sum -c` is only ever an executable instruction.
RECIPE = re.compile(r'sha256sum\s+-c\b')
# The era vocabulary already in use across the corpus for exactly this distinction. Any ONE of
# these within the window disambiguates which framing the recipe assumes.
ERA = re.compile(r'#169|SOLVE_COMPRESS=0|gzip\s+-dc|1f\s*8b|\bRAW\b|raw bytes|pre-#169', re.I)
WINDOW = 14        # lines either side; a code fence plus its explanatory comment block
pop = 0            # matching lines — reported, not floored
sites = set()      # distinct files — this is what the floor guards
bad = []
for f in files:
    try:
        lines = open(f, encoding="utf-8", errors="replace").read().split("\n")
    except OSError:
        continue
    for i, l in enumerate(lines):
        if not RECIPE.search(l):
            continue
        pop += 1
        sites.add(f)
        lo, hi = max(0, i - WINDOW), min(len(lines), i + WINDOW + 1)
        if not ERA.search("\n".join(lines[lo:hi])):
            bad.append((f, i + 1, l.strip()[:110]))
print("POP\t%d line(s) in %d file(s)" % (pop, len(sites)))
if len(sites) < floor:
    print("ERROR\tpopulation collapsed to %d file(s) (floor %d) — this gate is measuring nothing"
          % (len(sites), floor))
for f, ln, l in bad:
    print("HIT\t%s\t%d\t%s" % (f, ln, l))
PY
) || { echo "  [FAIL] GATE 28 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"
             echo "         A gate that passes because its subject vanished is not a green gate."
             rc=1 ;;
      HIT)   echo "  [FAIL] $a:$b publishes a sha256sum -c recipe with no framing-era qualifier"
             echo "         $c"
             echo "         Under the post-#169 default this command FAILS on a byte-correct artifact."
             rc=1 ;;
      POP)   echo "  [info] $a of published sha256sum -c recipe(s) in tracked markdown" ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every published sha256sum -c recipe states which framing era it assumes"
  return 0
}

gate_author_directives() {
  echo "== GATE 29: instructions to the AUTHOR surviving in published report prose =="
  # Q-352. TR-8 shipped a full technical-report masthead over what were four SECTION SUMMARIES
  # labelled "Structure (4 sections)", and a Verification Guide that addressed the WRITER, not the
  # reader: "section 2 CAN BE WRITTEN so that NOTHING depends on the estimator's absolute value" and
  # "PREFER the laptop-runnable framing throughout". reports/README.md lists TR-8 as a peer of
  # TR-1..TR-11 with an evidence column and no draft marker anywhere, so a reader was invited to
  # expect four written sections that do not exist.
  #
  # THE CLASS HAD ALREADY BEEN FIXED TWICE AND LEFT ONCE: TR-2 was relabelled at v1.13 and TR-3 was
  # written out into prose, both for this exact defect; TR-8 was skipped. And the finding's own claim
  # that TR-8 was the ONLY remaining case was wrong — TR-2 items 2 and 4 still carried
  # "Method in one page:", "Verifiability box." and "One paragraph on ... honestly".
  #
  # 🔴 THE EXEMPTION IS THE WHOLE DESIGN, and calibration is what forced it. Measured before writing
  # a line of this gate: after the fix, six of the eleven candidate patterns STILL matched 1-2 times
  # each — because the revision rows that RECORD the removal necessarily QUOTE the removed phrases.
  # A naive gate here would fire on the correction that fixed the defect: the tenth instance of the
  # Q-383 self-defeating-gate class in a week, authored by the fix for a different one. So an
  # occurrence is exempt when it sits in a revision-history row or inside a correction marker —
  # the same shape GATE 27 uses for withdrawn figures.
  #
  # 🔴 CLOSURE, and it cannot be a population floor, because ZERO live hits is the GOAL state here.
  # Instead the corrections themselves are the fixture: the gate must still FIND the quoted
  # occurrences inside those revision rows. If the pattern set matches nothing anywhere — not even
  # the rows that quote these phrases verbatim — the patterns have rotted and the gate is blind,
  # which is an ERROR, not a pass.
  local out
  out=$( { _md_norm_prelude; cat <<'PY'
import re, subprocess, sys
files = [f for f in subprocess.run(["git","ls-files","reports/*.md"],capture_output=True,text=True).stdout.split() if f]
if not files:
    print("ERROR\tgit ls-files matched no reports"); raise SystemExit(0)
# Directive shapes: modal-about-the-document, and meta-nouns naming a part as a thing to produce.
# 🔴 `can be written` ALONE IS TOO BROAD, and the gate's own first run proved it: it flagged
# METHODS.md:131, "it can be written as 'positions/values match King Wen's'" — a MATHEMATICAL
# can-be-expressed-as, not an instruction to an author. The discriminating feature of the real
# defect is that the modal is applied to a DOCUMENT PART: "section 2 can be written so that...".
# So the pattern is anchored to a section reference. This is the same lesson the CNKI passes paid
# for in a different domain: a term that matches the topic is not the same as a term that matches
# the shape you are hunting.
# Q-965 (A08#13): `[Ss]ection` -- "Section 2 should be written next." opens a sentence, and the
# capital S passed. The rest of RX stays case-sensitive on purpose (PREFER/TODO are marker conventions).
PATS = [r'(?:[Ss]ection|§)\s*\d+\s+can be written', r'(?:[Ss]ection|§)\s*\d+\s+should be written',
        r'\bPREFER\b', r'\bTODO\b',
        r'One paragraph (?:of|on)\b', r'\bVerifiability box', r'in one page:',
        r'Table of measured', r'note to self', r'\bwe (?:should|must) (?:write|add|state)\b',
        r'\bfair summary:']
RX = re.compile("|".join(PATS))
# Exempt: a revision-history row, or a line inside a correction marker.
def exempt(line):
    t = line.lstrip()
    return t.startswith('| v1.') or '⚠ **[' in line or 'CORRECTED' in line or 'relabelled' in line
seen = live = 0
hits = []
# Q-965: matched on the LOGICAL line (a paragraph joined by the shared normaliser, so a directive
# wrapped across lines is one directive); every other block kind per line. exempt() still reads the
# source line(s) the match spans.
for f in files:
    try: text = md_read(f)
    except OSError: continue
    lines = text.split("\n")
    units = []
    for b in md_parse(text)[2]:
        if b['kind'] == 'para': units.append(b)
        else: units += [md_para([(x, lines[x - 1])]) for x in range(b['start'], b['end'] + 1)]
    for u in units:
        for m in RX.finditer(u['text']):
            i, j = md_lno(u, m.start()), md_lno(u, m.end() - 1)
            l = " ".join(lines[i - 1:j])
            seen += 1
            if exempt(l): continue
            live += 1
            hits.append((f, i, m.group(0), lines[i - 1].strip()[:100]))
print("SEEN\t%d" % seen)
if seen == 0:
    print("ERROR\tthe directive pattern set matches NOTHING anywhere — not even the revision rows that quote these phrases verbatim. The patterns have rotted; this gate is blind.")
for f,i,w,l in hits:
    print("HIT\t%s\t%d\t%s\t%s" % (f,i,w,l))
# Structural leg: an outline heading must say it is summaries.
for f in files:
    try: body = open(f, encoding='utf-8', errors='replace').read()
    except OSError: continue
    seen_l = set()
    for m in re.finditer(r'^#+ *Structure \((\d+) sections?\)\s*$', body, re.M):
        seen_l.add(body[:m.start()].count("\n")+1)
        print("BARE\t%s\t%d" % (f, body[:m.start()].count("\n")+1))
    for b in md_parse(body)[2]:   # Q-965: indented and setext headings too
        if b['kind'] == 'heading' and b['start'] not in seen_l and re.fullmatch(r'Structure \(\d+ sections?\)', b['text']):
            print("BARE\t%s\t%d" % (f, b['start']))
PY
} | python3 - ) || { echo "  [FAIL] GATE 29 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c d; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      SEEN)  echo "  [info] $a occurrence(s) of the directive shapes, counting the corrections that quote them" ;;
      HIT)   echo "  [FAIL] $a:$b addresses the AUTHOR, not the reader — '$c'"
             echo "         $d"; rc=1 ;;
      BARE)  echo "  [FAIL] $a:$b heading 'Structure (N sections)' does not say the items are SUMMARIES."
             echo "         A masthead over an unlabelled outline invites a reader to expect sections that are not there."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] no report addresses its own author; every outline heading declares itself a summary list"
  return 0
}


# ==================================================================================
# GATES 30-35 (2026-09-02, code batch G1). Six legs queued in
# roae-private/PROSE_LANE_FOLLOWUPS.md as "the gate half is not built".
#
# 🔴 EVERY ONE OF THESE WAS RED-TESTED BEFORE IT WAS TRUSTED — the defect was
# reconstructed in a scratch clone, the gate was observed FAILING on it, and only then
# was it observed passing on the clean tree. A gate that has only ever passed has not
# been tested. The reconstructed defect for each is named in its own header.
#
# 🔴 THEY ALL FLATTEN. Four prose batches on 2026-09-02 found live sites only after
# whitespace-flattening the file, because the phrase spanned a hard wrap — GATE 3's
# lesson (a), relearned. `_g1_flatten` below is the shared normaliser and every text
# leg here runs on its output, never on a raw line. Line numbers survive the flattening
# through the `starts` offset table, so a finding still names a real source line.
#
# 🔴 A MISSING OR UNREADABLE INPUT IS AN ERROR, NEVER A ZERO. Each scanner emits
# `ERROR\t...` on an unreadable file or a collapsed population and each shell wrapper
# maps ERROR onto rc=1. This is the `[FAIL] ... printing 0 where it should have printed
# ERROR` class the suite has already been bitten by once.
#
# 🔴 AND THEY ALL CARRY A POPULATION FLOOR, for Codex N07's verifier-closure invariant:
# a verifier must be FALSE when its target is absent. A gate that passes because its
# subject vanished from the corpus is measuring nothing. Floors are set BELOW today's
# measured population and count the SUBJECT, never the fix's own commentary — the
# distinction GATE 28's header records paying for.
#
# The shared python prelude is duplicated into each heredoc rather than sourced: these
# are `python3 - <<'PY'` blocks with no import path between them, and a helper file
# would be a new gate-support input with its own missing-input question.
# ==================================================================================

# _g1_py — the prelude every G1 scanner starts with. Emitted into the heredoc by the
# caller so each scanner is self-contained; see the note above on why it is not a module.
# flatten(text) -> (flat, starts): `flat` is the whole file whitespace-normalised onto
#   ONE line (GATE 3's fold) -- and, since Q-965, each line is first folded by the shared
#   normaliser's inline fold (emphasis and backticks dropped, entities decoded, curly quotes and
#   dashes to ASCII, CRLF), which _g1_prelude now emits ahead of this block, so "not **yet**" and
#   "24 divides **every ...**" are read as written. `starts[i]` is the offset in `flat` at which source line
#   i+1 begins, so lno() recovers an exact source line for any flat offset.
# sent(flat,a,b): the flattened SENTENCE containing [a,b). Sentence, not line — the
#   qualifier legs below all ask "does the same sentence also say X".
# quoted(seg,a): True when offset a sits inside a quotation within seg. Callers pass the
#   END of the match, not its start: the claim shapes below often begin OUTSIDE the quotation
#   and end inside it (`called the k = 1 gain "the maximum by construction"`), and testing the
#   start read that as unquoted. Measured - it was this gate's first false positive, at
#   reports/TR4_SIZE_OF_THE_SPACE.md:433. A retracted
#   phrase QUOTED by the correction that retired it is narration, not assertion, and
#   exempting it is what stops these gates firing on their own fixes. Measured: without
#   it, GATE 30 fails on documentation/CORRECTIONS.md:4496-4497 and GATE 31 on :4121,
#   all three of which are the ledger describing the wording it removed.
_g1_prelude() {
_md_norm_prelude   # Q-965: the shared normaliser; flatten() below folds each line through it
cat <<'PRELUDE'
import re, sys, bisect, subprocess
_SUP = {'⁰':'0','¹':'1','²':'2','³':'3','⁴':'4',
        '⁵':'5','⁶':'6','⁷':'7','⁸':'8','⁹':'9'}
def desup(s):
    out=[]; i=0
    while i < len(s):
        if s[i] in _SUP:
            j=i
            while j < len(s) and s[j] in _SUP: j+=1
            out.append('^'+''.join(_SUP[c] for c in s[i:j])); i=j
        else:
            out.append(s[i]); i+=1
    return ''.join(out)
def corpus(pattern='*.md'):
    r = subprocess.run(["git","ls-files",pattern], capture_output=True, text=True)
    if r.returncode != 0:
        print("ERROR\tgit ls-files failed (%s) - NOTHING was checked" % r.returncode.__str__())
        raise SystemExit(0)
    return [f for f in r.stdout.split() if f]
def read(f):
    # An unreadable tracked file is an ERROR, not an empty document. Returning '' here
    # would make every text leg below report the file clean, which is the fail-open the
    # suite has already shipped once.
    try:
        return open(f, encoding='utf-8', errors='replace').read()
    except OSError as e:
        print("ERROR\t%s is unreadable (%s) - it was NOT checked" % (f, e.strerror))
        return None
_UNIT = re.compile(r'^\s*(?:[-*+]\s|\d+[.)]\s|#{1,6}\s|\|)')
def flatten(t):
    # Q-967 (Q-835 A08#14): a line break that ends a SCOPE UNIT is kept as "\n" (one character, so
    # every offset is unchanged): a blank line, a list item, a heading or a table row starts a new
    # unit, and sent() never crosses one. It was " ", so two bullets with no closing period read
    # as ONE sentence and a qualifier in an unrelated bullet ("- ... uses C3") counted.
    # Q-965 (A08#22, A08#24): each line is md_inline'd (emphasis, backticks, entities, curly quotes,
    # CR); the unit test reads the RAW line, so a list marker is seen before md_inline folds it.
    out=[]; starts=[]; off=0; prev=None
    for l in md_text(t).split("\n"):
        s=md_inline(l)
        if out:
            cut = (not s) or (not prev) or bool(_UNIT.match(l)) or prev.startswith(("#", "|"))
            out.append("\n" if cut else " "); off+=1
        starts.append(off); out.append(s); off+=len(s); prev=s
    return "".join(out), starts
def lno(starts,pos):
    return bisect.bisect_right(starts,pos)
# (integration, batch 40) a **BEFORE.** label does not end a sentence: md_inline drops the `**`, so the
# label's period would now cut the ledger's quoted old wording off from the BEFORE that narrates it
# (GATE 30 fired on the ledger's own BEFORE quotation); on the raw text the `**` after the period kept them together.
_SB = re.compile(r'(?<=[.!?])(?<!\bBEFORE\.)\s|\n')
def sent(flat,a,b):
    s=0
    for m in _SB.finditer(flat,0,a): s=m.end()
    m=_SB.search(flat,b)
    return flat[s:(m.start() if m else len(flat))]
# Q-967 (Q-835 A08#15): QUOTED is narration only when the sentence, outside its quotations, says
# it is narrating: a correction marker, a retired-phrase id, or a verb that reports wording.
# Quote parity alone made `We prove that "24 divides every exact solution count".` exempt.
_QSPAN = re.compile(r'"[^"]*"|“[^”]*”')
_QNARR = re.compile(r'\bBEFORE\b|\bNOW\b|CORRECTED|\bRP-[0-9a-f]{8}\b|\bRETIRED\b'
                    r'|(?i:\b(?:this read|read|reads|said|says|called|described|credited|labell?ed|wrote|written'
                    r'|registered|reworded|retired|retracted|withdr[a-z]*|corrected|superseded|previously'
                    r'|formerly|falsified|replaced|removed|struck|phrase|wording)\b)')
def quoted(seg,a):
    if (seg.count('"',0,a) + seg.count('“',0,a) + seg.count('”',0,a)) % 2 != 1:
        return False
    return bool(_QNARR.search(_QSPAN.sub(' ', seg)))
PRELUDE
}

# ----------------------------------------------------------------------------------
# GATE 30 — a pair-slot rotation-symmetry claim with no C3 exclusion.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P36 / Codex V2-F09 #1, "gate half".
# THE DEFECT: reports/TR7_CIRCULAR_READING.md §6 and documentation/CIRCULAR_KING_WEN.md
# §"Symmetry under closure" both asserted that, without C4, the 32 pair-slot rotations are
# symmetries of the circular constraint system. They are not: under the absolute-position
# C3 the suite actually uses, 21 of the 31 non-identity rotations of King Wen exceed the
# 776 ceiling (rotate-4 = 888, rotate-16 = 1240). The claim is true only if C3 is dropped
# or circularized, and neither sentence said so.
#
# 🔴 WHY A REGISTRY ROW IS NOT ENOUGH, and this is the finding's own argument: `RP-ed80aa5e`
# catches the exact retired string. This class survived one adjudication and was then
# REFILED at a sibling site, i.e. it recurs REWORDED, and a fixed string cannot see that.
# So the gate keys on the CLAIM SHAPE (rotations + symmetry) and demands the exclusion,
# not on any particular wording of it.
#
# RED TEST (2026-09-02, scratch clone): restored the pre-P36 sentence at
# CIRCULAR_KING_WEN.md §"Symmetry under closure" - "the 32 pair-slot rotations would be
# symmetries of a circular constraint system, alongside the B3 relabelings." with the
# C3 clause deleted. Gate went [FAIL] naming that line. Restored; gate [ok].
gate_rotation_c3() {
  echo "== GATE 30: a pair-slot rotation-symmetry claim that does not name C3 =="
  local FLOOR=4
  local out
  out=$( { _g1_prelude; _wm_prelude; cat <<'PY'

floor = int(sys.argv[1])
ROT = re.compile(r'(?:pair-slot|32)\s+rotations')
SYM = re.compile(r'symmetr', re.I)
C3  = re.compile(r'\bC3\b')
# Q-966 (A08#16): C3 is NAMED as the exclusion only when it is not conceded INTO the claim. "...are
# symmetries of the circular constraint system even with C3." names C3 and asserts the forbidden case.
# A mention whose 4 preceding words in its clause (shared matcher, wm_before) carry a concessive or
# inclusive cue does not count. Measured 2026-10-03: the 5 real C3 mentions in rotation-symmetry
# sentences ("only if C3 were dropped", "with the absolute-position C3 retained", "with a circularized
# C3", "the C3 ceiling", "only if C3 is also circularized") carry none.
C3_CONCEDE = {'even', 'including', 'regardless', 'despite', 'spite', 'plus', 'also'}
def c3_named(s):
    return any(not (set(wm_before(s, c.start(), 4)) & C3_CONCEDE) for c in C3.finditer(s))
pop = 0
for f in corpus():
    t = read(f)
    if t is None: continue
    flat, starts = flatten(t)
    for m in ROT.finditer(flat):
        s = sent(flat, m.start(), m.end())
        if not SYM.search(s):
            continue          # a rotation mentioned outside a symmetry claim is not the subject
        pop += 1
        if quoted(s, s.find(m.group(0)) + len(m.group(0))):
            continue          # the correction ledger quoting the wording it retired
        if c3_named(s):
            continue
        print("HIT\t%s\t%d\t%s" % (f, lno(starts, m.start()), s.strip()[:150]))
print("POP\t%d" % pop)
if pop < floor:
    print("ERROR\tonly %d pair-slot rotation-symmetry sentence(s) found (floor %d) - the claim shape has been reworded out of this gate's reach, so it is measuring nothing" % (pop, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 30 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   echo "  [info] $a pair-slot rotation-symmetry sentence(s) in the corpus" ;;
      HIT)   echo "  [FAIL] $a:$b claims pair-slot rotations are symmetries without naming C3"
             echo "         $c"
             echo "         Under the absolute-position C3 they are not: 21 of the 31 non-identity"
             echo "         rotations of King Wen exceed the 776 ceiling (rotate-4 = 888, rotate-16 = 1240)."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every rotation-symmetry claim states the C3 exclusion"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 31 — the S(k) marginal-gain curve, and the qualifier its maximum needs.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P34 / Codex V2-F06 charge 13,
# "prescribed mechanisation". The charge's own rationale for wanting a machine: this is
# the THIRD pass at one defect (v1.15 corrected the divisor, v1.16 found v1.15's
# propagation incomplete, P34 found two more sentences), so the class needs a gate and
# not a fourth reading.
#
# LEG 1 — ARITHMETIC. Every published per-boundary gain list must agree on its maximum,
# and the divisor the extrapolation uses must BE that maximum. The 126.6-bit budget was
# divided by 10.38, the k = 1 gain, asserted to be "the maximum by construction"; the
# same section's own list contains 11.10 at k = 3. Greedy maximises the UNCONDITIONAL
# gain and bounds no conditional one. Measured today: 4 lists, max 11.10 in all four.
# Note the maximum is DERIVED from the corpus, not hardcoded - if every list moved
# together the gate would follow them, which is correct; what it forbids is a divisor
# sentence and a gain list that disagree.
#
# LEG 2 — THE QUALIFIER. A sentence calling a measured single-boundary gain "the
# maximum" must say UNCONDITIONAL.
# 🔴 THE NEEDLE ALONE FAILS ON CORRECT PROSE, measured before this leg was written and
# the reason it has three exemptions rather than none:
#   * TR4:280 - "deriving one requires the maximum single-boundary information gain over
#     *all* boundaries and *all* conditioning contexts" is exactly RIGHT and needs no
#     "unconditional"; it is already quantified over contexts. Hence the `supremum` exemption.
#   * CORRECTIONS.md:4146-4147 - the ledger QUOTING the retired sentence. Hence `quoted`.
#   * HISTORY.md:5942 - narrates the divisor without attributing it to a first/greedy step.
#     Hence the requirement that the sentence attribute the maximum to the first/greedy gain.
# A gate that fired on any of these would be the self-defeating shape this suite keeps
# catching: a rule red on the correction that fixed the thing it hunts.
#
# RED TESTS (2026-09-02, scratch clone), one per leg:
#   LEG 1: changed TR4:302's list entry 11.10 -> 9.10, so the published max became 10.38
#          while the divisor sentence still says 11.10. Gate [FAIL] on the divisor
#          mismatch AND on the cross-file list disagreement. Restored; [ok].
#   LEG 2: deleted the word "unconditional" from SEARCH_SPACE_SIZE.md:278. Gate [FAIL]
#          naming that line. Restored; [ok].
gate_sk_gains() {
  echo "== GATE 31: the S(k) marginal-gain maximum, its divisor, and its qualifier =="
  local LIST_FLOOR=3 DIV_FLOOR=2 MAX_FLOOR=3
  local out
  out=$( { _g1_prelude; _wm_prelude; cat <<'PY'

list_floor, div_floor, max_floor = (int(a) for a in sys.argv[1:4])
# A published per-boundary gain list: five or more two-decimal values, comma separated.
LIST = re.compile(r'((?:\d+\.\d\d,\s*){4,}\d+\.\d\d)')
# 🔴 THE VALUE, NOT THE SENTENCE. This read `is the divisor` and asked whether the
# sentence mentioned the peak anywhere - and the red test walked straight through it,
# because TR-4's sentence names BOTH 11.10 and 10.38 while asserting one of them is the
# divisor. Swapping which one it asserts left the gate green. It now reads the number
# that is actually claimed.
DIV  = re.compile(r'(\d+\.\d+)\s+is the divisor')
# The claim shape leg 2 hunts, and its three discriminators.
MAXC = re.compile(r'maximum[^.]{0,80}?(?:single-boundary|per-boundary)[^.]{0,60}?gain'
                  r'|the (?:first|k = 1|step 1)[^.]{0,60}?(?:being |is )?the maximum')
FIRST = re.compile(r'\bfirst\b|\bgreedy\b|k *= *1|step 1|10\.38')
# The maximum a floor argument actually needs: quantified over CONTEXTS, not over the
# greedy path. A sentence that already says so needs no 'unconditional' and must not be
# failed for its absence (reports/TR4_SIZE_OF_THE_SPACE.md:280). Deliberately NOT a bare
# 'over all' - that would exempt any sentence containing the phrase, including one that
# says 'across all five measured steps', which is the defect's own wording.
SUPREMUM = re.compile(r'all\b[^.]{0,40}(?:conditioning|contexts)'
                      r'|over \*?all\*? [^.]{0,40}(?:boundaries|contexts)|supremum')
UNC = re.compile(r'unconditional', re.I)
# Q-966 (A08#17): SUPREMUM qualifies a sentence about THE maximum over all contexts; it is not a
# qualifier of a sentence that names the FIRST gain as that maximum. "the first gain is the maximum
# across all conditioning contexts" asserts the defect this leg exists for, and SUPREMUM exempted it.
# So a sentence of the second MAXC form ("the first/k = 1/step 1 ... is the maximum") is exempted by
# UNCONDITIONAL only, and SUPREMUM is read as whole words (shared matcher). Measured 2026-10-03: the
# one real SUPREMUM-only exemption (TR4 §5, the maximum over all boundaries and contexts) is of the
# first form and stays exempt.
FIRSTMAX = re.compile(r'the (?:first|k = 1|step 1)[^.]{0,60}?(?:being |is )?the maximum')
WM_SUPREMUM = wm_re(r'all\b[^.]{0,40}(?:conditioning|contexts)'
                    r'|over\s+\*?all\*?\s+[^.]{0,40}(?:boundaries|contexts)|supremum')
lists = []      # (file, line, values)
divs  = []      # (file, line, sentence)
maxes = []      # (file, line, sentence, offset-in-sentence)
for f in corpus():
    t = read(f)
    if t is None: continue
    flat, starts = flatten(t)
    for m in LIST.finditer(flat):
        vals = [float(x) for x in m.group(1).replace(" ", "").split(",")]
        lists.append((f, lno(starts, m.start()), vals))
    for m in DIV.finditer(flat):
        divs.append((f, lno(starts, m.start()), m.group(1), sent(flat, m.start(), m.end())))
    for m in MAXC.finditer(flat):
        s = sent(flat, m.start(), m.end())
        maxes.append((f, lno(starts, m.start()), s, s.find(m.group(0)) + len(m.group(0))))
print("POP\t%d gain list(s), %d divisor sentence(s), %d maximum-claim sentence(s)"
      % (len(lists), len(divs), len(maxes)))
if len(lists) < list_floor:
    print("ERROR\tonly %d published gain list(s) (floor %d) - the S(k) curve has left the corpus and this gate is measuring nothing" % (len(lists), list_floor))
if len(divs) < div_floor:
    print("ERROR\tonly %d divisor sentence(s) (floor %d) - the extrapolation's arithmetic is no longer stated in the words this gate reads" % (len(divs), div_floor))
if len(maxes) < max_floor:
    print("ERROR\tonly %d maximum-claim sentence(s) (floor %d) - leg 2's pattern set has rotted" % (len(maxes), max_floor))
# LEG 1a: every list must agree on its maximum.
if lists:
    peaks = sorted({max(v) for _, _, v in lists})
    if len(peaks) > 1:
        for f, ln, v in lists:
            print("LISTMAX\t%s\t%d\t%.2f\t%s" % (f, ln, max(v), "/".join("%.2f" % p for p in peaks)))
    peak = max(peaks)
    # LEG 1b: the divisor sentence must name that maximum.
    for f, ln, claimed, s in divs:
        if abs(float(claimed) - peak) > 0.005:
            print("DIVISOR\t%s\t%d\t%.2f (claimed %s)\t%s" % (f, ln, peak, claimed, s.strip()[:120]))
# LEG 2: a first/greedy maximum claim must be qualified UNCONDITIONAL.
for f, ln, s, off in maxes:
    if UNC.search(s) or (wm_has(s, WM_SUPREMUM) and not FIRSTMAX.search(s)):  continue
    if off >= 0 and quoted(s, off):          continue
    if not FIRST.search(s):                  continue
    print("UNCOND\t%s\t%d\t%s" % (f, ln, s.strip()[:150]))
PY
} | python3 - "$LIST_FLOOR" "$DIV_FLOOR" "$MAX_FLOOR" ) || { echo "  [FAIL] GATE 31 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c d; do
    case "$tag" in
      ERROR)   echo "  [FAIL] $a"; rc=1 ;;
      POP)     echo "  [info] $a" ;;
      LISTMAX) echo "  [FAIL] $a:$b publishes a gain list peaking at $c, but the corpus publishes peaks $d"
               echo "         Two documents disagree about the largest measured per-boundary gain."
               rc=1 ;;
      DIVISOR) echo "  [FAIL] $a:$b names a divisor that is not the published maximum gain ($c)"
               echo "         $d"
               echo "         The extrapolation must divide by the largest MEASURED gain, not by the k = 1 gain."
               rc=1 ;;
      UNCOND)  echo "  [FAIL] $a:$b calls a first/greedy single-boundary gain 'the maximum' without saying UNCONDITIONAL"
               echo "         $c"
               echo "         Greedy maximises the unconditional gain only; the measured k = 3 step exceeds k = 1."
               rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every gain list agrees on its maximum, every divisor is that maximum, every maximum claim is qualified"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 32 — the King Wen orientation-fiber anchors, cross-checked against their own prose.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, Codex V2-F48 #7 — "Add 1,720,320 and 2^31 to the
# doc-figure cross-check so a future edit of either site fails."
# THE DEFECT BEHIND IT: REBUILD_FROM_SPEC.md carried King Wen's collapsed orientation class
# as **4** (it is 1,720,320) and the enumerator's per-key orientation space as **2^32** (it
# is 2^31 — C4 pins slot 0's orientation, leaving 31 of 32 bits free). Both shipped for
# weeks; both were found by hand.
#
# 🔴 IT IS NOT A LIST OF HARDCODED CONSTANTS, and that is the whole design. Three anchors
# are named (1,720,320 C4-oriented / 983,040 flipped-opening / 2,703,360 pair-only-C4)
# ONLY to select the population — the sentences that talk about the fiber. What is then
# checked is DERIVED FROM THE PROSE: a published factorization must equal an integer the
# same sentence states, and a published sum must equal a total the same sentence states.
# Rewrite all three anchors consistently and this gate follows you; get one site's
# arithmetic wrong and it fails. A gate that only compared literals against a table
# would go stale the day the table did.
#
# 🔴 THE EXPONENT LEG WOULD FAIL ON CORRECT PROSE WITHOUT ITS SCOPE, measured before it
# was written: documentation/SOLVE.md:133 publishes "x 2^32 ... the number of ways to
# order 32 pairs and choose an orientation for each" — which is RIGHT, because that is the
# ambient space BEFORE C4 pins anything. The defect is only ever about the space
# recoverable from ONE stored pair-ordering, so the leg is scoped to sentences that say so
# (recoverable / per-key / C4-oriented / C4 pins / collapsed orientation). What that scope
# cannot see is a future defect written without any of that vocabulary; recorded, not hidden.
#
# RED TESTS (2026-09-02, scratch clone), one per leg:
#   FACT: changed documentation/SOLUTIONS_FORMAT.md:240 `3·5·7·2^14` -> `3·5·7·2^15`.
#         Gate [FAIL]: factorization evaluates to 3,440,640, which the sentence does not state.
#   SUM:  changed documentation/SOLVE.md:683 `983,040 reversed` -> `983,041 reversed`.
#         Gate [FAIL]: 1,720,320 + 983,041 is stated nowhere in that sentence.
#   EXP:  changed documentation/PROJECT_OVERVIEW.md:137 `2^31 combinations` -> `2^32`.
#         Gate [FAIL] naming that line.
#   CLOSURE: deleted every 1,720,320 from the corpus. Gate [FAIL] ERROR, not a pass.
gate_fiber_anchor() {
  echo "== GATE 32: the orientation-fiber anchors must survive their own arithmetic =="
  local FACT_FLOOR=4 SUM_FLOOR=2 EXP_FLOOR=6
  local out
  out=$( { _g1_prelude; _wm_prelude; cat <<'PY'
fact_floor, sum_floor, exp_floor = (int(a) for a in sys.argv[1:4])
ANCHORS = {1720320, 983040, 2703360}
# A comma-grouped integer as the corpus writes them. Bare digit runs are excluded on
# purpose: this population is prose, and prose here always groups these magnitudes.
INT  = re.compile(r'\b\d{1,3}(?:,\d{3})+\b')
# A product written as a factorization: 3·5·7·2^14, 48·48·64, 1024*1024.
FACT = re.compile(r'(?<![\d.])(\d+(?:[·*]\d+)+(?:\^\d+)?)(?![\d.])')
# A published sum. 🔴 NOT one regex spanning the '+': a single pattern with a slack gap
# is GREEDY ON THE WRONG SIDE, measured on this gate's first run - at
# documentation/SOLVE.md:682, "the pair-only-C4 fiber is 2,703,360 vectors (= 1,720,320
# forward + 983,040 reversed)", it paired 2,703,360 with 983,040 and reported a false
# 3,686,400 at three sites. The operands are therefore taken as the NEAREST grouped
# integer either side of the '+', which is what a reader takes them as.
# The '+' must be a BINARY operator: whitespace on both sides. Measured on this gate's
# second run - reports/TR1_EIGHT_CENTURIES_MEASURED.md:422 writes "2,703,360 vectors
# (+983,040 reversed-opening)", where the '+' is a SIGN on an annotation, not an
# addition, and reading it as one failed the gate on correct prose.
PLUS = re.compile(r'(?<=\s)\+\s(\d{1,3}(?:,\d{3})+)')
E31, E32 = re.compile(r'2\^31'), re.compile(r'2\^32')
# The per-key scope: the space recoverable from ONE stored pair-ordering, which is where
# C4 has already pinned slot 0. Outside this, 2^32 is the correct ambient figure.
PERKEY = re.compile(r'recoverab|per-key|per pair-ordering|C4-oriented|C4 pins'
                    r'|testing all|collapsed orientation')
CORRM  = re.compile(r'until 20\d\d-|corrected|previously|→|superseded', re.I)
WM_CORRM = wm_re(r'until\s+20\d\d|corrected|previously|superseded')   # Q-966: CORRM as whole words
nfact = nsum = n31 = nanchor = 0
for f in corpus():
    raw = read(f)
    if raw is None: continue
    t = desup(raw)
    flat, starts = flatten(t)
    if INT.search(flat):
        nanchor += sum(1 for x in INT.findall(flat) if int(x.replace(',', '')) in ANCHORS)
    for m in FACT.finditer(flat):
        s = sent(flat, m.start(), m.end())
        stated = {int(x.replace(',', '')) for x in INT.findall(s)}
        if not (stated & ANCHORS):
            continue                      # not a fiber sentence; out of this gate's scope
        v, expr = 1, m.group(1)
        try:
            for part in expr.replace('*', '·').split('·'):
                if '^' in part:
                    b, e = part.split('^'); v *= int(b) ** int(e)
                else:
                    v *= int(part)
        except ValueError:
            continue
        nfact += 1
        # Q-967 (Q-835 A08#18): a factorization the sentence EQUATES to an integer is compared with
        # THAT integer, not with every integer the sentence states. "1,720,320 = 3·5·7·2^15, whereas
        # 3,440,640 is the raw comparison" passed because the wrong product appeared elsewhere in it.
        # The bound integer is the grouped integer joined to the factorization by `=` (either side;
        # markup, spaces and an opening parenthesis allowed). A factorization that is not written as
        # an equation ("Reproduces 1,720,320 ..., the stated 3·5·7·2¹⁴ factorization") keeps the
        # sentence-level test: its product must be an integer the sentence states.
        lo, hi = m.start(), m.end()
        eq = (re.search(r'(\d{1,3}(?:,\d{3})+)[*`\s]*=[*`\s]*$', flat[max(0, lo - 40):lo])
              or re.match(r'^[*`\s]*=[*`\s]*\(?[*`\s]*(\d{1,3}(?:,\d{3})+)', flat[hi:hi + 40]))
        if eq and v != int(eq.group(1).replace(',', '')):
            print("FACT\t%s\t%d\t%s\t%d" % (f, lno(starts, m.start()), "%s (equated to %s)" % (expr, eq.group(1)), v))
        elif not eq and v not in stated:
            print("FACT\t%s\t%d\t%s\t%d" % (f, lno(starts, m.start()), expr, v))
    for m in PLUS.finditer(flat):
        s = sent(flat, m.start(), m.end())
        stated = {int(x.replace(',', '')) for x in INT.findall(s)}
        if not (stated & ANCHORS):
            continue
        left = None
        for lm in INT.finditer(flat, max(0, m.start() - 60), m.start()):
            left = lm            # nearest grouped integer to the LEFT of the '+'
        if left is None or '+' in flat[left.end():m.start()]:
            continue
        a = int(left.group(0).replace(',', '')); b = int(m.group(1).replace(',', ''))
        nsum += 1
        if a + b not in stated:
            print("SUM\t%s\t%d\t%s + %s\t%d" % (f, lno(starts, m.start()), left.group(0), m.group(1), a + b))
    for m in E31.finditer(flat):
        if PERKEY.search(sent(flat, m.start(), m.end())) and not wm_negated(flat, m.start()): n31 += 1
    for m in E32.finditer(flat):
        s = sent(flat, m.start(), m.end())
        if not PERKEY.search(s):        continue
        # Q-966 (A08#19): a 2^31 that the sentence NEGATES ("2^32, not 2^31") is the wrong exponent
        # asserted, not the fix narrated; and the correction words are whole words (shared matcher), so
        # "uncorrected" is not "corrected".
        if (any(not wm_negated(s, x.start()) for x in E31.finditer(s))
                or '\u2192' in s or wm_has(s, WM_CORRM)): continue   # the ledger narrating the 2^32 -> 2^31 fix
        print("EXP\t%s\t%d\t%s" % (f, lno(starts, m.start()), s.strip()[:140]))
print("POP\t%d anchor mention(s), %d factorization(s), %d sum(s), %d per-key 2^31 site(s)"
      % (nanchor, nfact, nsum, n31))
if nanchor == 0:
    print("ERROR\tno fiber anchor (1,720,320 / 983,040 / 2,703,360) appears anywhere in the corpus - every leg below selected an EMPTY population and checked nothing")
if nfact < fact_floor:
    print("ERROR\tonly %d fiber factorization(s) (floor %d) - the FACT leg is measuring nothing" % (nfact, fact_floor))
if nsum < sum_floor:
    print("ERROR\tonly %d fiber sum(s) (floor %d) - the SUM leg is measuring nothing" % (nsum, sum_floor))
if n31 < exp_floor:
    print("ERROR\tonly %d per-key 2^31 site(s) (floor %d) - the EXP leg is measuring nothing" % (n31, exp_floor))
PY
} | python3 - "$FACT_FLOOR" "$SUM_FLOOR" "$EXP_FLOOR" ) || { echo "  [FAIL] GATE 32 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c d; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"
             echo "         A gate that passes because its subject vanished is not a green gate."
             rc=1 ;;
      POP)   echo "  [info] $a" ;;
      FACT)  echo "  [FAIL] $a:$b factorization '$c' = $d, which is not the integer its sentence equates it to or states"
             echo "         A published factorization must equal the integer it factorizes."
             rc=1 ;;
      SUM)   echo "  [FAIL] $a:$b published sum '$c' totals $d, which this sentence does not state"
             echo "         The C4-oriented fiber plus the flipped-opening fiber is the pair-only-C4 fiber."
             rc=1 ;;
      EXP)   echo "  [FAIL] $a:$b gives the per-key orientation space as 2^32; C4 pins slot 0, so it is 2^31"
             echo "         $c"
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every fiber factorization, sum and per-key exponent agrees with its own sentence"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 33 — an unqualified "strongest measured discriminator".
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P37 / Codex V2-F08 charge 22, "tooling
# half". THE DEFECT: TR-6 §6 carried "the strongest measured literature discriminator"
# unqualified for months while CITATIONS.md and LITERATURE_RULES_POPULATION_TESTS.md both
# already published the successor (the data-like S25-28 configuration at ×5×10⁷ against
# Schulz's ×11,364). A superlative outlived its own scoreboard.
#
# 🔴 WHY P37 REFUSED TO REGISTER THIS AS A GATE 3 NEEDLE, which is why the item exists at
# all: the retracted thing is an unqualified SHAPE, not a string. A bare needle on
# "strongest measured ... discriminator" is red on the LEGITIMATELY QUALIFIED twin in
# CITATIONS.md - and that twin SPANS A LINE WRAP, so it is invisible to an unflattened
# matcher and visible to a flattened one. P37 had to hand-cut a comma-trailed needle
# precise enough to miss it. This gate flattens (so it sees the twin) and then asks
# whether the same sentence carries a temporal or category qualifier (so it passes it).
# MEASURED at authoring time: 7 occurrences, 0 unqualified. One match itself spans a wrap
# (documentation/CITATIONS.md:1976-1977, "strongest measured literature / discriminator")
# and at that same site the QUALIFIER "at the time of the SAT work" is on the following
# source line again — so both the needle and its exemption are line-based-invisible there.
#
# 🔴 SCOPE, stated rather than implied. The item asks for a SECOND leg — generate the
# scoreboard's current champion FROM LITERATURE_RULES_POPULATION_TESTS.md instead of
# restating it in each citing document. That is a generator, not a gate, and it is NOT
# built here. This gate attests the qualifier and nothing about whether the successor
# figure each site quotes is still the champion.
#
# RED TEST (2026-09-02, scratch clone): deleted "at the time of the SAT work (×11,364),
# later exceeded by the data-like S25-28 configuration at ×5×10⁷" from
# reports/TR6_PARITY_SKELETON.md:133-134, restoring the pre-P37 bare superlative. Gate
# [FAIL] naming that line. Restored; [ok]. A second red test confirmed the wrap case:
# deleted the qualifier from documentation/CITATIONS.md:1976-1977, where the superlative
# and its qualifier sit on DIFFERENT source lines - gate [FAIL], as flattening requires.
gate_superlative() {
  echo "== GATE 33: a 'strongest measured discriminator' with no qualifier =="
  local FLOOR=4
  local out
  out=$( { _g1_prelude; _wm_prelude; cat <<'PY'
floor = int(sys.argv[1])
SUP = re.compile(r'strongest measured[^.]{0,40}?discriminator')
# Temporal or category scoping. Any ONE of these makes the superlative a statement about a
# named population or moment rather than an unqualified championship claim.
QUAL = re.compile(r'at the time of|as of \d|later exceeded|then-|until 20\d\d'
                  r'|in the scoreboard table|of the population-measured|among the'
                  r'|\bin this\b', re.I)
# The ledger's own word for what it removed. A sentence that SAYS the phrase was
# unqualified is narrating the correction; failing it would be the self-defeating shape.
NARR = re.compile(r'unqualified|\bBEFORE\.|Corrected 20\d\d|RP-[0-9a-f]{8}')
# Q-966 (A08#20): 'headline finding' was a QUAL and qualifies nothing ("Our headline finding is that
# Schulz is the strongest ..." passed); it is dropped. 'unqualified' NARRATES only as a predicate of
# the old wording -- whole word, followed by punctuation or a quote ('called "...", unqualified.') --
# never as the adjective of the superlative itself ("the unqualified strongest ..." passed). Measured
# 2026-10-03: no real site depended on either (both 'unqualified' sites are also quoted or dated).
WM_NARR = wm_re(r'unqualified(?=\s*(?:[.,;:)\]"\u201c\u201d\'\u2019]|$))|BEFORE\.|Corrected\s+20\d\d|RP-[0-9a-f]{8}', 0)
pop = wrapped = 0
for f in corpus():
    t = read(f)
    if t is None: continue
    flat, starts = flatten(t)
    for m in SUP.finditer(flat):
        pop += 1
        s = sent(flat, m.start(), m.end())
        if lno(starts, m.start()) != lno(starts, m.end()):
            wrapped += 1
        if quoted(s, s.find(m.group(0)) + len(m.group(0))): continue
        if wm_has(s, WM_NARR):                              continue
        if QUAL.search(s):                                  continue
        print("HIT\t%s\t%d\t%s" % (f, lno(starts, m.start()), s.strip()[:150]))
print("POP\t%d superlative(s), %d of them spanning a line wrap" % (pop, wrapped))
if pop < floor:
    print("ERROR\tonly %d 'strongest measured ... discriminator' occurrence(s) (floor %d) - the phrase has been reworded out of this gate's reach and it is measuring nothing" % (pop, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 33 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   echo "  [info] $a" ;;
      HIT)   echo "  [FAIL] $a:$b publishes an UNQUALIFIED 'strongest measured ... discriminator'"
             echo "         $c"
             echo "         The scoreboard has a successor; the superlative needs its era or its population."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every 'strongest measured discriminator' names its era or its population"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 34 — a published ratio must equal the quotient printed beside it.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P36 / Codex V2-F09 #3, "gate half".
# THE DEFECT: TR-7 priced Cook's final-pair anchor as ×1.25 — that is 7.84 / 6.25, against
# the 1/16 counting baseline — while the MEASURED d = 3 class average of 6.52 was printed
# two lines below. 7.84 / 6.52 is ×1.20. The document contained everything needed to catch
# itself and nobody divided.
#
# 🔴 FLATTENING IS LOAD-BEARING HERE AND WAS MEASURED TO BE. TR-7 writes the second split
# as "**×1.20 is / the A₂-specific residual** (7.84 / 6.52)" across a hard wrap. An
# unflattened scan of the corpus finds ONE of TR-7's two ratios; a flattened scan finds
# both. Half a gate that reports PASS is the scope-narrowing failure this suite exists to
# catch, so this is recorded rather than left to be rediscovered.
#
# 🔴 IT MUST NOT EAT SCIENTIFIC NOTATION. '×10⁻³' is a magnitude, not a ratio, and a first
# cut of this leg matched "×10⁻³ against 2·(0.05/91)" at TR-10:107 and :505 and
# "×10⁻⁶ | ×200,000 | **fails** (16/18)" at TR-1:110 — four false positives, all
# arithmetic that was never claimed. A multiplier of exactly 10 carrying an exponent is
# therefore excluded, and the parenthesised form requires the quotient to be adjacent.
#
# TOLERANCE: the quotient must round to the published ratio at the ratio's OWN printed
# precision. 6.52 / 3.2258 = 2.02116..., published ×2.02 — correct at two decimals and it
# must not be failed for that.
#
# RED TEST (2026-09-02, scratch clone): restored TR-7's pre-P36 ratio, changing
# "**×1.20 is the A₂-specific residual** (7.84 / 6.52)" to "**×1.25 …** (7.84 / 6.52)".
# Gate [FAIL]: 7.84 / 6.52 = 1.2025, published ×1.25. Restored; [ok]. The red test was run
# on the WRAPPED site specifically, because that is the one an unflattened gate cannot see.
gate_printed_quotient() {
  echo "== GATE 34: a published ×ratio must equal the quotient printed beside it =="
  local FLOOR=3
  local out
  out=$( { _g1_prelude; cat <<'PY'
floor = int(sys.argv[1])
# Q-968 (A08#21): the operands are read by the shared number lexer (md_normalise.sh), so a grouped
# "1,007.84" is one number. The ratio is MD_MAG directly after the ×, and the scientific-magnitude
# exemption is now decided by SYNTAX: "×10⁻³" / "×10^3" / "×10³" carries an exponent and is not
# matched (the lookahead); a bare "×10" is a ratio of ten and IS a claim. Until Q-968 the exemption
# was `r == 10`, so every ratio equal to 10 left the population, and so did every zero denominator
# (`b == 0`). A zero denominator is now a loud HIT: the printed quotient cannot be checked.
N = MD_UNUM
R = r'(?![\d,.]?\d)(?!\^|[⁰¹²³⁴⁵⁶⁷⁸⁹⁻⁺])'
# Shape A: "6.52 / 3.2258 = **×2.02**"     Shape B: "**×2.02 …** (6.52 / 3.2258)"
A = re.compile(r'(%s)\s*/\s*(%s)\s*=\s*\**[×x](%s)%s' % (N, N, MD_MAG, R))
B = re.compile(r'[×x](%s)%s\**[^()]{0,120}?\((%s)\s*/\s*(%s)\)' % (MD_MAG, R, N, N))
found = []
for f in corpus():
    t = read(f)
    if t is None: continue
    flat, starts = flatten(t)
    for m in A.finditer(flat):
        a, b, r = (md_num(x) for x in m.groups())
        found.append((f, lno(starts, m.start()), a, b, r, m.group(0)))
    for m in B.finditer(flat):
        r, a, b = (md_num(x) for x in m.groups())
        found.append((f, lno(starts, m.start()), a, b, r, m.group(0)))
kept = 0
for f, ln, a, b, r, txt in found:
    if r.exp is not None and re.match(r'10(?:\^|[⁰¹²³⁴⁵⁶⁷⁸⁹⁻⁺])', r.raw):
        continue                       # a magnitude written as a power of ten (×10⁻³), not a ratio
    kept += 1
    try:
        q = float(md_ratio(a, b))
    except MdNumError as e:
        print("HIT\t%s\t%d\t%s\t%s" % (f, ln, txt.strip()[:90], e))
        continue
    sc = 10.0 ** (r.exp or 0)          # "×1.2×10³" is judged on its mantissa, at the mantissa's decimals
    if round(q / sc, r.dp) != round(float(r.value) / sc, r.dp):
        print("HIT\t%s\t%d\t%s\t%.4f" % (f, ln, txt.strip()[:90], q))
print("POP\t%d published quotient claim(s)" % kept)
if kept < floor:
    print("ERROR\tonly %d published quotient claim(s) (floor %d) - this gate is measuring nothing" % (kept, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 34 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c d; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   echo "  [info] $a" ;;
      HIT)   echo "  [FAIL] $a:$b published ratio disagrees with its own printed quotient"
             echo "         $c   — the division gives $d"
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every published ×ratio equals the quotient printed beside it"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 35 — a status word outliving the work it describes.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P34 / Codex V2-F06 charge 16,
# "prescribed mechanisation", including the shape: "'queued' within N lines of a heading
# matching Update (20..-..-..)".
# THE DEFECT: TR-4 §5 said the S(6)-S(8) work was "queued" and would "sharpen further when
# S(6..8) land" — within twenty lines of the dated Update heading that REPORTS S(6)-S(8)
# measured. P34 registered `hit rates); queued` as RP-b1c1f805, which catches that one
# site and nothing else; the class is a status word that outlived its work.
#
# 🔴 ITS POPULATION IS ONE HEADING, AND THAT IS STATED RATHER THAN AVERAGED AWAY. The whole
# tracked corpus contains exactly ONE dated Update heading (TR-4:298), measured both on the
# prescribed pattern and on a deliberately widened one that also admits bold and
# "Updated". So this gate is, today, a regression guard on one section — not a corpus
# sweep — and its floor is correspondingly 1. It is worth its 40 lines because that section
# has now had the same defect twice, and because the floor makes the gate ERROR rather than
# pass if the heading is ever renamed out from under it. It is NOT worth quoting as
# corpus-wide coverage of the status-word class, and no banner here says it is.
#
# RED TEST (2026-09-02, scratch clone): restored the pre-P34 wording at
# reports/TR4_SIZE_OF_THE_SPACE.md:361, just above the 2026-07-05 Update heading —
# "sharpens further when S(6..8) land". Gate [FAIL] naming that line and the heading it
# contradicts. Restored; [ok]. Closure red test: renamed the heading to "### Later work",
# and the gate went [FAIL] ERROR (population 0) rather than reporting clean.
gate_stale_status() {
  echo "== GATE 35: a status word surviving beside the dated update that completed it =="
  local FLOOR=1 WINDOW=20
  local out
  out=$( { _g1_prelude; cat <<'PY'
floor, window = int(sys.argv[1]), int(sys.argv[2])
# The prescribed heading pattern, widened to bold/"Updated" forms. Measured 2026-09-02:
# both the narrow and the widened form select exactly one heading in the tracked corpus.
HEAD = re.compile(r'^\s*(?:#+|\*\*|__)?\s*Update[ds]?\b[^|]{0,80}\(20\d\d-\d\d-\d\d\)')
# Forward-looking status vocabulary. "when ... land" is included because it was HALF of
# the actual defect ("sharpens further when S(6..8) land") and a bare "queued" needle would
# have caught only the other half.
# 🔴 THE GAP IS `.{0,40}?` AND NOT `[^.]{0,40}`, which is what it was first written as and
# what let the red test walk straight through: the defect's own text is "when S(6..8) land"
# and `S(6..8)` CONTAINS DOTS. The file's SAFETY rule bans bounded repetition because a
# POSIX ERE `.{0,80}X.{0,60}` once hung this box; that hazard is two unanchored bounded
# reps under grep -oE. This is ONE lazy bounded rep in python re over a <=41-window inside
# an already-bounded slice of the file, which is linear in the window.
STALE = re.compile(r'\bqueued\b|\bnot yet\b|\bstill pending\b|\bwill land\b'
                   r'|\bwhen\b.{0,40}?\blands?\b', re.I)
heads = 0
for f in corpus():
    t = read(f)
    if t is None: continue
    lines = t.split("\n")
    hs = [i for i, l in enumerate(lines) if HEAD.match(l)]
    heads += len(hs)
    for h in hs:
        lo, hi = max(0, h - window), min(len(lines), h + window + 1)
        # 🔴 THE WINDOW IS FLATTENED, not scanned line by line. A status phrase that spans a
        # hard wrap is invisible to a line scan — GATE 3's lesson (a), and the reason four
        # prose batches on 2026-09-02 found live sites only after flattening. The heading's
        # own line is blanked first so the gate never fires on the heading it anchors to.
        win = list(lines[lo:hi]); win[h - lo] = ""
        flat, starts = flatten("\n".join(win))
        for m in STALE.finditer(flat):
            print("HIT\t%s\t%d\t%d\t%s" % (f, lo + lno(starts, m.start()), h + 1,
                                             flat[max(0, m.start() - 40):m.end() + 40].strip()[:120]))
print("POP\t%d dated update heading(s), window +/-%d lines" % (heads, window))
if heads < floor:
    print("ERROR\tno dated update heading found (floor %d) - the heading this gate is anchored to has been renamed, so it is measuring nothing" % floor)
PY
} | python3 - "$FLOOR" "$WINDOW" ) || { echo "  [FAIL] GATE 35 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c d; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   echo "  [info] $a" ;;
      HIT)   echo "  [FAIL] $a:$b describes work as pending, beside the dated update heading at $a:$c"
             echo "         $d"
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] no pending-status word survives beside a dated update that completes it"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 36 — an "N-path equivalence" heading whose table does not have N rows, and two
# sites publishing a different N for the same campaign (Codex V2-F12 #3, prose batch P43,
# 2026-09-02).
#
# WHY THIS EXISTS. documentation/HISTORY.md headed a table "8-path equivalence at 11.2T
# proven" and listed SEVEN rows, and had done since the table was written. The review that
# found it concluded no eighth path existed and prescribed renumbering the heading to seven
# — which would have deleted a real validation path (the post-#45 recovery cascade,
# described in the same file 175 lines below) from the public record. The count was right
# and the table was short. Two further sites in the same file published "7-path" for the
# same campaign, and neither was named in the charge.
#
# So the defect class is a PUBLISHED COUNT WITH A PUBLISHED DENOMINATOR NEXT TO IT: the
# heading asserts N and the table beneath it is the enumeration of N. Nothing in the suite
# compared them, and a reader who counts rows is the only instrument that ever did.
#
# LEG 1 (hard): every "<N>-path equivalence|validation" occurrence that DIRECTLY owns a
# markdown table — only blank lines and the table's own header row may intervene, and the
# separator row must be within ADJ lines — must have exactly N data rows in that table. An
# occurrence with no such table is a MENTION, not a heading, and LEG 1 skips it; it is
# LEG 2's business. Adjacency rather than a loose window is not a refinement, it is the
# gate's first measured finding: a 20-line window fired on two prose mentions sitting above
# an unrelated table.
#
# LEG 2 (hard): every occurrence in the corpus must publish the same N. This is correct
# TODAY because the corpus documents exactly one N-path campaign (the 2026-05 11.2T
# validation). WHAT THIS CANNOT SEE, stated rather than left to be discovered: if a SECOND
# campaign is ever published with a different path count, LEG 2 will fire on correct prose
# and the fix is to scope it by campaign (e.g. by the scale token beside the phrase), NOT
# to widen the needle or delete the leg. The population line prints every distinct N so
# that outcome is legible the moment it happens.
#
# FLOORS. The gate ERRORs — not passes — if it finds fewer than FLOOR_OCC occurrences or
# no table-anchored one at all, because both are the state in which it is measuring
# nothing. Measured 2026-09-02: 4 occurrences, 1 of them table-anchored, all N = 8.
#
# NOT FLATTENED, and here is why that is safe rather than an oversight: GATE 3's lesson is
# that a PHRASE spanning a hard wrap is invisible to a line scan. The needle here is a
# single token ("8-path") plus one following word, and a markdown table's structure is
# line-based by definition — flattening would destroy the very rows LEG 1 counts. The
# residual exposure is a wrap falling between "8-path" and "equivalence", which no
# formatter produces and which LEG 2 would still catch at the other sites.
#
# RED TEST (2026-09-02, in the working tree, restored immediately after each):
#   (a) deleted the recovery-cascade row -> LEG 1 [FAIL] "heading publishes 8, table has 7".
#   (b) changed one "8-path validation" to "7-path validation" -> LEG 2 [FAIL] naming both
#       values and every site carrying each.
#   (c) closure: raised both floors to 99 in place -> two [FAIL] ERROR lines naming the
#       measured populations (7 occurrences, 1 table-anchored), not a clean pass. The floors
#       were exercised rather than the needle renamed, because renaming it means editing
#       seven live sites; the floor is the mechanism under test either way, and it is the
#       one that fires if the phrase is ever reworded out from under this gate.
gate_npath() {
  echo "== GATE 36: an N-path equivalence heading must enumerate N paths, and N must agree =="
  local FLOOR_OCC=2 FLOOR_TABLE=1 ADJ=4
  local out
  out=$( { _g1_prelude; cat <<'PY'
floor_occ, floor_tab, adj = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
NEEDLE = re.compile(r'\b(\d+)-path\s+(?:equivalence|validation)\b', re.I)
SEP    = re.compile(r'^\|[\s|:-]+\|\s*$')
occ = []
for f in corpus():
    t = read(f)
    if t is None: continue
    lines = t.split("\n")
    # Q-965 (A08#10): the table under the heading is found by the shared normaliser, so a GFM table
    # without edge pipes, or indented, is a table (a pipe-less 2-row table under "## 8-path
    # equivalence" passed, since SEP wanted a leading `|`).
    _L, KIND, BLOCKS, _u = md_parse(t)
    TAB = {}
    for blk in BLOCKS:
        if blk['kind'] == 'table':
            for x in range(blk['start'], blk['end'] + 1): TAB[x - 1] = blk
    for i, l in enumerate(lines):
        for m in NEEDLE.finditer(l):
            n = int(m.group(1))
            # ADJACENCY, NOT A WINDOW. First cut allowed the separator anywhere in a
            # 20-line window and that immediately fired on two PROSE MENTIONS 40 lines
            # above an unrelated table (measured 2026-09-02, the gate's first run). A
            # heading owns the table DIRECTLY beneath it: only blank lines and the table's
            # own header row may intervene, and the separator must be within ADJ lines.
            rows = None
            for j in range(i + 1, min(len(lines), i + 1 + adj)):
                s = lines[j].strip()
                if j in TAB and (KIND[j] == 'tdelim' or SEP.match(s)):
                    rows = len([r for r in TAB[j]['rows'] if r[0] > j + 1])
                    break
                if s == "" or KIND[j] in ('thead', 'trow'):
                    continue
                break
            occ.append((f, i + 1, n, rows, l.strip()[:100]))
tabled = [o for o in occ if o[3] is not None]
for f, ln, n, rows, txt in tabled:
    if rows != n:
        print("ROWS\t%s\t%d\t%d\t%d\t%s" % (f, ln, n, rows, txt))
vals = sorted(set(o[2] for o in occ))
if len(vals) > 1:
    for v in vals:
        where = ", ".join("%s:%d" % (o[0], o[1]) for o in occ if o[2] == v)
        print("SPLIT\t%d\t%s" % (v, where))
print("POP\t%d occurrence(s), %d table-anchored, N value(s) seen: %s"
      % (len(occ), len(tabled), ",".join(str(v) for v in vals) or "none"))
if len(occ) < floor_occ:
    print("ERROR\tfewer than %d N-path occurrences in the corpus (found %d) - the phrase this gate is anchored to has been reworded, so it is measuring nothing" % (floor_occ, len(occ)))
if len(tabled) < floor_tab:
    print("ERROR\tno N-path heading is directly followed by a table (within %d lines, floor %d) - LEG 1 checked nothing" % (adj, floor_tab))
PY
} | python3 - "$FLOOR_OCC" "$FLOOR_TABLE" "$ADJ" ) || { echo "  [FAIL] GATE 36 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c d e; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   echo "  [info] $a" ;;
      ROWS)  echo "  [FAIL] $a:$b publishes $c paths and the table beneath it has $d data row(s)"
             echo "         $e"
             echo "         Fix the TABLE unless the count is genuinely wrong — renumbering the heading"
             echo "         deletes a validation path from the record, which is how this gate was earned."
             rc=1 ;;
      SPLIT) echo "  [FAIL] N=$a published at: $b"
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every N-path heading enumerates N paths, and every site publishes the same N"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 37 — a relative STANDARD ERROR published as a +- band.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P40 / Codex V2-F35 #4 — "a bare percentage
# beside a published `95% CI [a, b]` must equal (b - mean)/mean", red-test site README.md.
#
# 🔴 THE PRESCRIBED RULE WAS RE-DERIVED AND CHANGED, AND THE REASON IS MEASURED. The charge asks
# for a percentage checked against a bracket that stands beside it. Its own named red-test site,
# README.md's residual bullet, carries NO bracket — `grep -n "95% CI" README.md` returns :63 and
# :191 and neither is that bullet — so the rule as written cannot fire on the one defect it was
# written for. A gate that passes its target is worse than no gate, because it certifies it.
#
# WHAT THE DEFECT ACTUALLY IS, stated so the check can be arithmetic. The estimator prints
# `mean +- 1.96*sqrt(vhat/N)` and a relerr of SE/mean (METHODS.md, "Statistics conventions"). A
# count with relative standard error r therefore costs, in bits, log2(1+r) at ONE sigma and
# log2(1+1.96r) at 95%. README.md published "the +-0.78% C1-C7 estimate ~= +-0.01 bits":
#     log2(1.0078)          = 0.01121   -> rounds to 0.01, the figure that was printed
#     log2(1 + 1.96*0.0078) = 0.02189   -> rounds to 0.02, the figure that should have been
# and the published [5.13, 5.29]x10^31 bracket gives -0.0223/+0.0220 independently. So the
# property is decidable with no lookup and no bracket: a stated precision that reproduces the
# ONE-SIGMA conversion of a stated relerr, and does NOT reproduce the 95% one, is a standard
# error wearing an error bar. That is the 2026-08-28 relerr-is-not-an-error-bar ruling, made
# checkable.
#
# PRECISION IS TAKEN FROM THE PAGE, NOT ASSUMED. Each candidate is compared at the number of
# decimals the document itself printed - "0.01" is judged at 2 dp, "0.011" at 3 - which is the
# same technique GATE 34 uses on published ratios. A fixed tolerance would either miss the
# rounded site or swallow the corrected one.
#
# TWO EXEMPTIONS, BOTH MEASURED, BOTH COUNTED IN THE OUTPUT SO NEITHER CAN GROW UNSEEN:
#   * documentation/CORRECTIONS.md, entirely. Quoting the defect it withdrew is the ledger's
#     job and GATE 10a makes it append-only, so the text could not be edited even if it were
#     wrong. Same exemption, same reason, as GATES 26 and 27. Measured: 4 pairs, 3 units.
#   * a unit carrying BOTH a supersession word and a date. DESCRIPTION_LENGTH.md's 2026-08-06
#     change-note quotes its own superseded "+-0.011 bits" and then says, in the same paragraph,
#     that the figure "no longer stand[s] as written ... corrected or withdrawn on 2026-09-02".
#     Marked is the cured state; the DATE requirement is what keeps a bare "corrected" anywhere
#     in a paragraph from being a free pass. Measured: 2 pairs in 1 unit. ⚠ ITS LIMIT, STATED: a genuinely
#     new defect written inside a dated correction paragraph would escape. That is a narrower
#     hole than GATE 27's (which accepts a supersession word alone) and it is the price of not
#     firing on the corpus's own history.
#
# THE UNIT IS A LIST ITEM OR PARAGRAPH, NOT A LINE. The percentage and the band are 30 words
# apart in README and markdown wraps wherever it likes; a line-scoped check is one reflow away
# from silence. Splitting at blank lines AND at every list-item / table-row start keeps a
# neighbouring bullet's correction marker from exempting the bullet next to it.
#
# 🔴 THE FLOOR. If fewer than FLOOR units in the whole corpus pair a percentage with a bit-band,
# this gate has nothing to measure and says so instead of passing. Measured population 2026-09-02:
# TEN units, so the floor of 4 leaves room for ordinary rewording while still catching a collapse
# to nothing. Proven by raising it to 9999 in place: "[FAIL] only 10 unit(s) ... floor 9999 - this
# gate is measuring nothing", rc 1 — an ERROR, not a pass.
#
# RED TEST (2026-09-02, measured, both directions, on a full copy of the corpus):
#   BEFORE README.md's fix -> [FAIL] README.md:<line> 0.78% with +-0.01 bits (line 240 of that day's working tree), rc 1, exactly one HIT.
#   AFTER  README.md's fix -> [ok], rc 0, with the candidate and exemption census unchanged.
#   MUTANT (the charge's own rule, i.e. compare against the 95% conversion instead of the
#     1-sigma one) -> fires on documentation/DESCRIPTION_LENGTH.md and reports/TR9... , the two
#     pages that are CORRECT, and stays silent on README. Recorded because it is the exact
#     inversion a future "simplification" would produce.
# ⚠ OWED: a permanent `--selftest` fire-proof pair. Not written blind — see the same note under
#   GATE 26 LEG 2. Write it, and RUN it, on a clean committed tree.
# ----------------------------------------------------------------------------------
gate_se_vs_ci() {
  echo "== GATE 37: a relative standard error may not be published as a +- band =="
  local FLOOR=4
  local out
  out=$( { _g1_prelude; _wm_prelude; cat <<'PY'
import math
floor = int(sys.argv[1])
PCT  = re.compile(r'(?<![0-9.])(\d{1,2}(?:\.\d+)?)\s*%')
CONF = re.compile(r'\b(?:90|95|99)(?:\.\d+)?\s*%')
# Q-968 (A08#23): the band is read by the shared number lexer, so ASCII "+/-0.01 bits" is a band
# exactly as "±0.01 bits" is; only the band forms (pm) are kept, as before only ± was.
BITS = re.compile(r'(%s)\s*bits?' % MD_NUM)
MARK = re.compile(r'(?i)(corrected|withdrawn|superseded|no longer stand)')
DATE = re.compile(r'\b20\d\d-\d\d-\d\d\b')
NEW  = re.compile(r'\s*(?:[-*+]\s|\d+\.\s|\|)')
# Q-966 (A08#11): MARK through the shared word matcher -- whole words, a negated marker is none. As
# substrings, "uncorrected as of 2026-09-03" exempted a 1-sigma band as a dated correction.
WM_MARK = wm_re(r'corrected|withdrawn|superseded|no\s+longer\s+stand')
cand = ex_ledger = ex_marked = 0
for f in corpus():
    t = read(f)
    if t is None:
        continue
    lines = t.split("\n")
    units = []
    buf = []
    start = 1
    for i, l in enumerate(lines, 1):
        if (not l.strip() or NEW.match(l)) and buf:
            units.append((start, buf)); buf = []
        if not l.strip():
            continue
        if not buf:
            start = i
        buf.append(l)
    if buf:
        units.append((start, buf))
    for start, buf in units:
        text = " ".join(buf)
        # the confidence LEVEL is not a relative error; mask 90/95/99% before reading percentages
        pcts = sorted(set(m.group(1) for m in PCT.finditer(CONF.sub(" CONF ", text))))
        bits = sorted(set(("%.*f" % (n.dp, float(n.mag)), n.dp, float(n.mag))
                          for n in (md_num(m.group(1)) for m in BITS.finditer(text)) if n.pm))
        if not pcts or not bits:
            continue
        cand += 1
        for ps in pcts:
            r = float(ps) / 100.0
            if r <= 0:
                continue
            s1 = math.log2(1 + r)
            c95 = math.log2(1 + 1.96 * r)
            for bs, dp, x in bits:
                # the published band reproduces ONE sigma and does NOT reproduce 95%
                if round(s1, dp) != x or round(c95, dp) == x:
                    continue
                if f == "documentation/CORRECTIONS.md":
                    ex_ledger += 1
                    continue
                if wm_has(text, WM_MARK) and DATE.search(text):
                    ex_marked += 1
                    continue
                print("HIT\t%s\t%d\t%s\t%s\t%.5f\t%.5f\t%s"
                      % (f, start, ps, bs, s1, c95, " ".join(text.split())[:150]))
print("CENSUS\t%d\t%d\t%d" % (cand, ex_ledger, ex_marked))
if cand < floor:
    print("ERROR\tonly %d unit(s) in the corpus pair a percentage with a bit-band (floor %d) - this gate is measuring nothing" % (cand, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 37 scanner failed — NOTHING was checked."; return 1; }
  local rc=0 cand="" exl="" exm=""
  while IFS=$'\t' read -r tag a b c d e g h; do
    case "$tag" in
      ERROR)  echo "  [FAIL] $a"; rc=1 ;;
      CENSUS) cand=$a; exl=$b; exm=$c ;;
      HIT)    echo "  [FAIL] $a:$b publishes a relative STANDARD ERROR as a +- band"
              echo "         $c% relerr with \"±$d bits\": log2(1+r)=$e rounds to $d at this precision,"
              echo "         log2(1+1.96r)=$g does not. The 95% figure is the one to publish, or say SE."
              echo "         … $h"
              rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  if [ -z "$cand" ]; then
    echo "  [FAIL] GATE 37 printed no census line — the scan did not complete, so nothing was checked."
    return 1
  fi
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] $cand unit(s) pair a percentage with a bit-band; every published band reproduces the"
  echo "       95% conversion, not the 1-sigma one. Exempt: $exl percentage/band pair(s) in the"
  echo "       append-only ledger, $exm carrying a dated supersession marker — both counted so"
  echo "       neither exemption can grow unseen."
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 38 — a mod-24 divisibility claim may not be stated as an UNRESTRICTED UNIVERSAL.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, "doc_gates legs prescribed by P12's sheet" —
# "`divisible by 24` proximity leg", with the sheet's own warning that the sibling sites
# "may already carry a local level qualifier; do not assume either way".
#
# THE DEFECT (fb696340, prose P16): lean/README.md read "24 divides **every exact solution
# count**". The Lean theorem does not say that. It says 24 divides the length of any
# DUPLICATE-FREE COMPLETE LISTING of the RECORD-LEVEL solution set, for a G-invariant
# predicate containing C1. Drop those restrictions and the claim is false of the counts
# this suite actually publishes: TR-11 v1.13 and TR-5's own note establish that the
# ORIENTATION-EXPLICIT sequence-level counts sit in orbits of size 48, so mod-24 is the
# strictly weaker gate there, and METHODS.md:75 records "mod-24 N/A under pins" for the
# C6/C7-pinned layer, where the free action does not hold at all.
#
# 🔴 WHAT THIS LEG IS *NOT*, measured before it was written rather than after. The sheet's
# literal "proximity" shape — every `divisible by 24` sentence must name its authority —
# was BUILT AND MEASURED FIRST and is NOT what shipped. Over the tracked corpus it returns
# 47 occurrences with 11 unqualified, and inspection of all 11 found ZERO defects: they are
# revision rows, correction markers narrating the level-attribution fix, and table cells
# whose "sentence" is an entire row. A leg with 11 false positives and no true one is a
# demand that eleven correct sentences be reworded, which is the disclosure-penalising
# shape this suite is under standing instruction not to build. Recorded here so the shape
# is not re-proposed as an oversight.
#
# 🔴 POPULATION vs PREDICATE ARE DELIBERATELY DIFFERENT SETS. The population is every
# mod-24 divisibility claim in the corpus (stable, ~45); the predicate fires only on the
# unrestricted-universal SHAPE. Keying the floor to the predicate's own matches would make
# the floor 1 — the surviving quoted copy inside the CORRECTED marker — and a gate whose
# population is one quoted string ERRORs the moment that marker is reworded. Keyed this
# way, the floor tracks the thing that would actually have to disappear for the gate to be
# measuring nothing.
#
# 🔴 IT MUST NOT FAIL THE CORRECTION THAT WITHDREW IT. lean/README.md:25 still contains the
# retired sentence VERBATIM, inside the dated `[CORRECTED 2026-08-30 — this read "…"]`
# marker that withdrew it, because CORRECTIONS are append-only and a withdrawal has to
# quote what it withdrew. Two independent exemptions cover it — the prelude's `quoted()`
# (the phrase sits inside double quotes) and a narration regex — and BOTH are counted and
# printed, so neither can grow unseen.
gate_dvd24_scope() {
  echo "== GATE 38: a mod-24 divisibility claim stated as an unrestricted universal =="
  local FLOOR=10
  local out
  out=$( { _g1_prelude; _wm_prelude; cat <<'PY'
floor = int(sys.argv[1])
# POPULATION: any mod-24 divisibility claim at all.
POP = re.compile(r'divisib\w{0,4} by 24|indivisible by 24|\bmod[- ]24\b|24 divides|divides\b[^.]{0,30}\bby 24')
# PREDICATE: the divisibility asserted over an unrestricted universal class of counts.
U = re.compile(r'(?:24|twenty-four)\s+divides\s+(?:the\s+length\s+of\s+)?(?:every|all|any|each)\b[^.]{0,60}?count'
               r'|(?:every|all|any|each)\s+exact\s+(?:solution\s+)?count[^.]{0,40}?(?:divisib\w+ by 24|\bmod[- ]24\b)',
               re.I)
# The restriction the theorem actually carries. Tested against the MATCHED QUANTIFIER SPAN,
# never the sentence. 🔴 THIS SCOPE WAS SET BY A FAILED RED TEST, not by taste: with the
# check on sentence scope the gate went GREEN on its own pre-fix baseline, because the
# retired sentence states the restriction as its PREMISE ("they act freely at the record
# level in 24-element orbits") and then over-generalises in its CONCLUSION ("and therefore
# 24 divides every exact solution count"). A restriction word anywhere in the sentence is
# therefore evidence of nothing. It has to qualify the quantified noun phrase itself.
RESTR = re.compile(r'duplicate-free|record[- ]level|complete listing', re.I)
# A correction quoting the sentence it retired is doing its job; failing it would be the
# self-defeating shape. Same-scope only — the SENTENCE, never a line window.
NARR = re.compile(r'CORRECTED 20\d\d|this read|\bBEFORE\.|RETIRED|withdraw|RP-[0-9a-f]{8}')
# Q-966: NARR and ANARR below as whole, un-negated words (shared matcher).
WM_NARR = wm_re(r'CORRECTED\s+20\d\d|this\s+read|BEFORE\.|RETIRED|withdraw\w*|RP-[0-9a-f]{8}', 0)
pop = ex_quoted = ex_narr = 0
for f in corpus():
    t = read(f)
    if t is None: continue
    flat, starts = flatten(t)
    pop += len(POP.findall(flat))
    for m in U.finditer(flat):
        s = sent(flat, m.start(), m.end())
        if RESTR.search(m.group(0)):
            continue
        if quoted(s, s.find(m.group(0)) + len(m.group(0))):
            ex_quoted += 1
            continue
        if wm_has(s, WM_NARR):
            ex_narr += 1
            continue
        print("HIT\t%s\t%d\t%s" % (f, lno(starts, m.start()), " ".join(m.group(0).split())[:150]))
print("POP\t%d mod-24 divisibility claim(s); %d retired-wording copy(ies) exempt as quoted, %d as narration" % (pop, ex_quoted, ex_narr))
# LEG 2 — ATTRIBUTION (CX-232, 2026-09-29; the LSD review's R4 / K01-2, triaged by Fable). A sentence
# that cites the Lean `twenty_four_dvd_*` theorems for a divisibility claim about N, a flow, a walk,
# |SUPER|, a layer count or the gate itself must say that the theorems are RECORD-level, or that
# the sequence-level gate rests on the PAPER-PROVED order-48 action. Those theorems count `SolRec`
# listings; the published counts are orientation-explicit sequences (lean/README.md, the 2026-08-30
# note). Unit: the flattened sentence around each citation in *.md, the line in
# scripts/tr12_repro.sh (which prints the gate's own header). Measured before shipping, by restoring the
# five b0abe4e5 files into the fixed tree: this leg fires at PREREG_CLASSA_QUERY_SET.md:127,
# TR12_QUERY_PROGRAM.md:2152, TR5_SYMMETRY.md:159 and tr12_repro.sh:3039; on the fixed tree it fires
# nowhere. QUERY_INVENTORY.md:278's old wording is not caught by this sentence unit; a
# RETRACTED_PHRASES.tsv row carries that site.
AOBJ = re.compile(r'\bflows?\b|\bwalks?\b|\|SUPER\||layer count|\bN\b|\bgate\b')
AOK = re.compile(r'record[- ]level|paper-proved|\b48\b', re.I)
# Q-966 (A08#25): a bare 48 is not an attribution ("... divisibility of N in run 48." passed). The
# paper-layer attribution is the ORDER-48 ACTION, so 48 counts only in that phrase; and every AOK form
# is a whole, un-negated word (shared matcher). Measured 2026-10-03: no real citation relied on a bare 48.
WM_ANARR = wm_re(r'CORRECTED\s+20\d\d|this\s+read|BEFORE\.|RETIRED|withdraw\w*|RP-[0-9a-f]{8}')
WM_AOK = wm_re(r'record[- ]level|paper-proved|order[- ]48|orbits?\s+of\s+48|48-element|group\s+of\s+order\s+48')
ANARR = re.compile(r'CORRECTED 20\d\d|this read|\bBEFORE\.|RETIRED|withdraw|RP-[0-9a-f]{8}', re.I)
apop = 0
for f in corpus() + ['scripts/tr12_repro.sh']:
    t = read(f)
    if t is None: continue
    if f.endswith('.sh'):
        units = [(i + 1, l) for i, l in enumerate(t.split("\n"))]
    else:
        flat, starts = flatten(t)
        units = [(lno(starts, m.start()), sent(flat, m.start(), m.end())) for m in re.finditer(r'twenty_four_dvd', flat)]
    for n, u in units:
        if 'twenty_four_dvd' not in u: continue
        apop += 1
        if AOBJ.search(u) and not wm_has(u, WM_AOK) and not wm_has(u, WM_ANARR):
            print("AHIT\t%s\t%d\t%s" % (f, n, " ".join(u.split())[:150]))
print("POP\t%d twenty_four_dvd citation(s) checked for their record-level / paper-layer attribution" % apop)
if apop < 5:
    print("ERROR\tonly %d twenty_four_dvd citation(s) found (floor 5) - the attribution leg is measuring nothing" % apop)
if pop < floor:
    print("ERROR\tonly %d mod-24 divisibility claim(s) in the corpus (floor %d) - the class has been reworded out of this gate's reach and it is measuring nothing" % (pop, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 38 scanner failed — NOTHING was checked."; return 1; }
  local rc=0
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   echo "  [info] $a" ;;
      HIT)   echo "  [FAIL] $a:$b states mod-24 divisibility as an UNRESTRICTED UNIVERSAL"
             echo "         $c"
             echo "         The theorem restricts to a duplicate-free complete listing of the"
             echo "         RECORD-LEVEL set. Sequence-level counts sit in orbits of 48, and the"
             echo "         C6/C7-pinned layer has no free action at all (METHODS.md:75, 'N/A under pins')."
             rc=1 ;;
      AHIT)  echo "  [FAIL] $a:$b cites twenty_four_dvd_* for a sequence-level count without its level"
             echo "         $c"
             echo "         Those theorems are RECORD-level (SolRec listings). Say so, or say the gate on"
             echo "         the published counts rests on the paper-proved order-48 action (CX-232)."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every mod-24 divisibility claim carries the restriction the theorem quantifies over"
  echo "  [ok] every twenty_four_dvd_* citation for a sequence-level count names its level (CX-232)"
  return 0
}

