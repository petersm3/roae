#!/usr/bin/env bash
# citation_line_gate.sh — a `solve.c:NNNNN` citation must LAND on a line that contains the
# flag or symbol the citing sentence names.
#
# WHY. documentation/SOLVE_C_CLI.md carries ~100 hand-maintained `solve.c:NNNNN` line
# citations into a 44,000-line file under continuous edit. A line citation is the one kind of
# cross-reference that goes wrong SILENTLY: nothing in the document changes when solve.c is
# restructured, so a citation that pointed at the right function keeps rendering, keeps looking
# authoritative, and now points at an unrelated statement. MEASURED 2026-09-07 while this gate
# was being written: every one of the 38 citations in the `--kc-*` subcommand tables had drifted,
# with NON-UNIFORM offsets (+3229, +3655, +4749) — i.e. accumulated over several separate
# restructurings, so no single bulk shift could have repaired them and no reviewer reading one
# citation could have inferred the state of the others. They have since been repaired; this gate
# is the reason the repair does not have to happen a fourth time by hand.
#
# WHAT IS CHECKED. For every `solve.c:N` or `solve.c:N-M` in the document, the citing doc LINE is
# mined for DISTINCTIVE identifiers — `--flags`, `SOLVE_*` environment names, and backticked
# C identifiers of length >= 5 containing an underscore or fully upper-case. Generic English and
# bare C keywords are excluded by construction (they carry no underscore and are not flags), and
# so are wildcard stems ending in `_` (`SOLVE_*` rendered as `SOLVE_`). A candidate that does not
# occur ANYWHERE in solve.c is dropped, because it is prose, not a symbol. What remains is the set
# of things the sentence CLAIMS is at that line. The citation LANDS if at least one of them occurs
# within the cited span; it is STALE otherwise. A citation whose line yields no candidate is
# counted and reported as UNCHECKABLE, never as agreement.
#
# HEADING FALLBACK, and why it is most of the gate. The single commonest citation shape in this
# document names its subject in the section heading, not in the sentence: "Dispatched as a
# subcommand at `solve.c:<N>`; takes **none**." under a `### --kc-...` heading. Mining the
# citing line alone leaves those UNCHECKABLE, which is precisely the population that had drifted
# — a gate blind to its own defect class. So when the line yields no candidate, the nearest
# PRECEDING markdown heading is mined instead. MEASURED 2026-09-07: checkable citations go from
# 38/101 to 95/101, uncheckable from 63 to 6, and every one of the repaired `--kc-*` citations
# LANDS, which is the independent confirmation that the fallback resolves to the right symbol.
#
# NO LINE NUMBER IS HARDCODED — both files are read from disk on every run, which is required:
# solve.c is edited continuously, so any pinned line would be wrong within the day. That also
# means a solve.c edit ALONE can turn this gate red, and that is the intended direction: the
# citation really did go stale, and the person moving the code is the person who can fix it.
#
# WHAT IS PINNED (a RATCHET, not a pass mark). Measured on this tree 2026-09-07: 101 citations,
# 95 checkable, 57 STALE. Shipping a hard FAIL at 25 sites would put a red gate in front of every
# push on day one, and the next morning nobody would read it — the Q-199 defect this repo has
# already adopted as policy (see doc_gates.sh, GATE 2 usage-grammar leg). So the 25 are pinned in
# TWO independent ways and BOTH must hold:
#   (1) COUNT budget      — the number of stale citations may never RISE.
#   (2) KEY allow-list    — the SYMBOL of every stale citation must already be known-open.
# (2) exists because (1) alone has the fix-one/break-one hole: repair one citation, introduce
# another, and the count is unchanged. The key is the lexicographically first distinctive
# candidate on the citing line, which is a property of the two files' CONTENT and is therefore
# stable under the line drift in either file that (1) is measuring.
# The budget may only ever be LOWERED. A count that RISES is a FAIL; a count that FALLS is
# ANNOUNCED, loudly, so the pin tightens in the same change — a budget resting on repaired defects
# is headroom for new ones. (A fall is announced rather than failed because solve.c is under
# continuous edit by other lanes: an unrelated edit can make a stale citation land again by
# coincidence, and that must not block their push.)
#
# KNOWN-OPEN, not acceptable: the keys in KNOWN_KEYS below are real stale citations in
# documentation/SOLVE_C_CLI.md. They are pinned rather than bulk-patched because repairing a
# citation requires deciding WHICH of several candidate sites the sentence meant — an editorial
# call per site, and documentation/ is held by another lane.
#
# Verdict: prints exactly one CITATION_LINE_GATE=<PASS|FAIL|ERROR> line. Consume with grep -qx.
# ERROR is distinct from FAIL on purpose: it means the gate MEASURED NOTHING (no citations found,
# or a file unreadable). A gate that measured nothing must never read as agreement.
#
# Self-test: `scripts/citation_line_gate.sh --selftest` runs the red-test in both directions on
# synthetic files (see the leg list in that block). CITGATE_DOC / CITGATE_SRC override the pair
# under test; they exist FOR that self-test.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "CITATION_LINE_GATE=ERROR"; exit 40; }

DOC="${CITGATE_DOC:-documentation/SOLVE_C_CLI.md}"
SRC="${CITGATE_SRC:-solve.c}"
# THE RATCHET. Lower only, and only in the same change that repairs a citation.
# 🔴 PIN MOVED 57 -> 0 in the same pass that drained it (2026-09-07). A pin left at 57 after the
# work is done is a gate that has stopped gating: it would have tolerated 57 NEW stale citations.
# Measured after the drain: 99 citations, 97 checkable, 0 stale, 2 structurally uncheckable (their
# sentences name only `#include <zlib.h>` and a gcc command line, neither of which yields a
# distinctive identifier). Standing risk, stated rather than discovered later: at 0 this goes RED
# the moment another lane shifts solve.c under those 97 citations -- which happened TWICE today,
# once by a uniform +43. That is the intended direction, but it hard-blocks the pushing lane, so
# the number is a deliberate choice and not an accident of when the drain finished.
BUDGET="${CITGATE_BUDGET:-0}"
KNOWN_KEYS="${CITGATE_KEYS:-}"

_run() {
  DOC="$1" SRC="$2" BUDGET="$3" KEYS="$4" python3 - <<'PYEOF'
import os, re, sys
doc_p, src_p = os.environ["DOC"], os.environ["SRC"]
budget = int(os.environ["BUDGET"])
known = {k for k in os.environ["KEYS"].split(",") if k}
try:
    src = open(src_p, encoding="utf-8", errors="replace").read().split("\n")
    doc = open(doc_p, encoding="utf-8", errors="replace").read().split("\n")
except OSError as e:
    print("ERROR unreadable: %s" % e); sys.exit(0)

def candidates(line):
    """Distinctive identifiers the citing sentence names. Prose and bare C keywords carry no
    underscore and are not flags, so they never survive; wildcard stems (`SOLVE_`) are dropped."""
    out = set()
    for m in re.finditer(r'`([^`\n]{1,80})`', line):
        for w in re.findall(r'--[a-z0-9][a-z0-9-]{2,}|[A-Za-z_][A-Za-z0-9_]*', m.group(1)):
            if w.startswith("--") or (len(w) >= 5 and ("_" in w or w.isupper())):
                out.add(w)
    out |= set(re.findall(r'\b(SOLVE_[A-Z0-9_]{2,})\b', line))
    out |= set(re.findall(r'(?<![\w-])(--[a-z0-9][a-z0-9-]{2,})', line))
    return {w for w in out if w != "solve" and not w.endswith("_")}

total = checked = 0
stale = []
heading = ""
for li, line in enumerate(doc, 1):
    if line.startswith("#"):
        heading = line
    for m in re.finditer(r'solve\.c:(\d+)(?:\s*-\s*(\d+))?', line):
        total += 1
        a = int(m.group(1)); b = int(m.group(2) or a)
        lo, hi = min(a, b), max(a, b)
        # The citing sentence first; its section heading only when the sentence names nothing.
        cs = candidates(line) or candidates(heading)
        cs = {c for c in cs if any(c in l for l in src)}
        if not cs:
            continue
        checked += 1
        span = "\n".join(src[lo - 1:hi])
        if not any(c in span for c in cs):
            stale.append((li, m.group(0), sorted(cs)[0], sorted(cs)))

# A gate that measured nothing must ERROR, never PASS.
if total == 0:
    print("ERROR no solve.c:NNNNN citation found in %s" % doc_p); sys.exit(0)
if checked == 0:
    print("ERROR %d citation(s) found but NONE was checkable (no symbol named)" % total); sys.exit(0)

print("COUNT total=%d checked=%d stale=%d uncheckable=%d" % (total, checked, len(stale), total - checked))
seen = set()
for li, cite, key, cs in stale:
    seen.add(key)
    tag = "OPEN" if key in known else "NEW"
    print("%s %s:%d %s names %s" % (tag, doc_p, li, cite, ",".join(cs[:4])))
if len(stale) > budget:
    print("VERDICT FAIL stale count %d EXCEEDS pinned budget %d" % (len(stale), budget))
elif seen - known:
    print("VERDICT FAIL new stale citation key(s): %s" % ", ".join(sorted(seen - known)))
else:
    if len(stale) < budget:
        print("VERDICT-CONT REPIN: stale count %d is BELOW the pinned budget %d -- lower BUDGET in"
              % (len(stale), budget))
        print("VERDICT-CONT the same change, or the headroom becomes room for a new stale citation.")
    print("VERDICT PASS %d stale, all known-open, budget %d" % (len(stale), budget))
PYEOF
}

# ==================================================================================================
# --all-files MODE (Q-786, 2026-09-25). The mode above reads ONE document. MEASURED 2026-09-25: a
# single solve.c change (batch 8, +1,193 lines at 3 points) silently staled 56 `solve.c:N`
# citations in 21 OTHER tracked files, plus 4 in RETRACTED_PHRASES.tsv, none of which this gate
# read; they were found by hand and re-pinned by content (Opus UU). `--all-files` closes that
# population with two legs that fail for different reasons:
#
#   LEG A — SHIFT (content-free, change-scoped). Given a base ref (--base REF, else $CITGATE_BASE,
#     else HEAD), `git diff -U0 BASE -- solve.c` is turned into the old->new line map by hunk
#     arithmetic. Every citation in every tracked TEXT file (git grep -I) whose citing line is
#     BYTE-IDENTICAL to a line of the same file at BASE — i.e. a citation this change did not
#     touch — and whose N (or either end of N-M) lies past a hunk, so that map(N) != N, is a FAIL,
#     printed as file:line with map(N). This needs no anchor at all, so it also covers the
#     citations leg B cannot check. Its population is only what the change moved; with the default
#     base on a clean committed tree it is vacuous by design, and says so. A citation whose N falls
#     INSIDE a rewritten hunk has no image; it is printed as [inhunk] for leg B to judge, not failed.
#
#   LEG B — ANCHOR (content, a ratchet). The single-document check above, generalised to every
#     tracked *.md / *.py / *.sh: anchors are mined from the citing line (backticked identifiers
#     and verbatim backticked code fragments, --flags, SOLVE_* names, bare snake_case identifiers,
#     "string literals"; markdown falls back to the nearest heading, as above) and filtered to those
#     that occur somewhere in solve.c. The citation LANDS if one occurs within [N-2, M+2]. The
#     +-2 slack admits "the call is on the next line" prose without admitting a shifted block.
#     Stale citations are pinned PER FILE, by key (the sorted-first anchor, stable under drift),
#     each with a reason, in ALL_PINS below. The pin is EXACT in both directions: a stale key not
#     pinned is a FAIL, and a pinned key that no longer goes stale is ALSO a FAIL ("tighten the
#     pin") — a pin resting on a repaired defect is headroom for a new one.
#
# SHARED EXCLUSIONS (by pattern, both legs). Paths: documentation/CORRECTIONS.md,
# documentation/HISTORY.md, documentation/CORRECTIONS_INVENTORY.tsv, reports/evidence/ — append-only
# or frozen records whose line numbers are true AT THE DATE THEY STATE. Lines: a Codex finding id
# (`Codex v2 solve.c:8073` names Codex's snapshot, not HEAD); a revision pin (`at <hex sha>`,
# `@<hex sha>`, `<sha>:solve.c`, `git show <sha>:solve.c`) -- judged PER CITATION within 40
# characters since Q-791, not per line; a citation glued to `@`; a dated
# revision row (a table row whose first cell is a date or a version, or a TSV row carrying a
# `Retracted|Added|Corrected YYYY-MM-DD` provenance note). Every exclusion is COUNTED and printed
# by class, so a pattern that starts swallowing live citations shows up as a moving number.
#
# Verdict: one CITATION_LINE_GATE=<PASS|FAIL|ERROR> line, as above. ERROR = measured nothing
# (no git work tree, an unresolvable explicit --base, or no checkable citation in leg B's scope).
#
# ==================================================================================================
# --all-files --all-targets (Q-791, 2026-09-25). Q-786 closed `solve.c:N` in every file; nothing
# read `<file>:N` for any OTHER target, and those drift the same way. MEASURED on the integrated
# batch 1-8 tree (Opus ZZ): 88 citations into 22 other files left behind by that one staged change
# (leg A), and ~200 leg-B misses, most of them stale since long before it (the tr12_repro.sh line
# cited for the n>=31 rank3 parse was ~500 lines off; the cited SOLVE_C_CLI.md build line had
# moved ~1,500). Every one was repaired BY CONTENT or pinned below with a reason. Same two legs,
# same exclusions, plus:
#   * TARGET RESOLUTION against `git ls-files`: an exact path, else relative to the citing file's
#     directory, else the unique path ending in `/<name>`, else the one in the citing file's own
#     directory. Unresolvable (a private-repo file, host:port) and ambiguous names are COUNTED.
#   * GRAMMAR: a markdown link glued to its number (`[X.md](X.md):N`) and a backticked name glued
#     to it (`` `x.out`:14 ``) are citations. A bare `(:N)`, `` `:N` ``, `at :N` or `see :N` with no `<file>:N` before it
#     on its line is read as the last file NAMED earlier on that line, else the last `<file>:N` in
#     the preceding lines of its paragraph, else the citing file ITSELF -- the self-reference shape
#     (the bare `(:N)` notes in tr12_repro.sh) that no grammar read. CITGATE_PINROWS=1 prints each inference.
#   * A candidate that is a tracked file's NAME is dropped: it is how prose points at a document.
#   * REVISION PINS are judged per citation (40 characters either side), `<file>:N@<sha>` is the
#     compact historical form, and a pinned head carries its `:N` continuations on the same line.
#     Use it for a citation that records a PAST tree ("measured at X", "the pre-fix line") rather
#     than repinning it to whatever holds that line number today.
#   * Codex batch locators `(BATCH A03 row 22, F.md:N)` / `Codex A01 row 32 (F.md:N)` name Codex's
#     snapshot and are excluded, like the `Codex v2 solve.c:N` ids above.
# Pins: ALL_PINS (solve.c) plus TARGET_PINS below, keyed (citing file, target, anchor key).

# THE --all-files PIN TABLE: <file> TAB <key> TAB <reason>. One row per pinned stale citation;
# a file's budget IS its row count. Lines starting with # are comments. Empty = no known-open.
# MEASURED 2026-09-25 (Opus XX, on the integrated batch 1-8 tree): leg B 241 citations in scope,
# 24 stale; leg A 1 shifted. 4 of the 24 were genuinely stale and were FIXED by content, not pinned
# (CRITIQUE.md x2; SOLVE_C_CLI.md x2, both `:N` continuations the document mode never reads), as was
# leg A's one (a comment in solve.c citing solve.c); 2 were tests.py headers that are Codex v2
# finding ids and now say so (their third sibling too). The 18 left are the rows below, each either
# HISTORICAL/SELF-ANNOTATED (the citation means a past tree, by its own words) or LANDS by
# inspection with no anchor the miner can see -- the gate's false positives, listed rather than
# hidden. None is a known-wrong live citation.
# A LANDS row still has leg A behind it: a shift under it fails leg A regardless of this pin.
ALL_PINS_DEFAULT=$(cat <<'PINS'
# file	key	reason
documentation/DEVELOPMENT.md	update_progress	HISTORICAL by its own words: the callsite 'in the 2026-05-15 tree', a line of a named past tree, not of HEAD
documentation/QUERY_INVENTORY.md	--kc-profile	QUOTES the retired wrong citation 16664ff (Q-540) to explain its re-anchoring; the live usage-block citation on the same row lands
documentation/QUERY_INVENTORY.md	--kc-profile	the second number of that same quotation (16664 is a sidecar-write comment, which is the row's point)
documentation/QUERY_INVENTORY.md	(d, w)	LANDS: line 28002 opens the `"kernel"` object of raw cells (Opus UU repin, content-checked 2026-09-25); the placeholder m<a>_<b> is not source text and `kernel` is a plain word
documentation/SEARCH_SPACE_SIZE.md	E[W at a reached depth-32 leaf]	LANDS: line 8344 is `double se = sqrt(var / dn)`, the SE the sentence says is computed correctly; the sentence names no symbol of it
documentation/VERIFY.md	--help	SELF-ANNOTATED: the sentence itself says this number is stale and names f5_nuc's current line (dated 2026-09-21); keeping the retired number visible is an editorial choice
reports/TR12_QUERY_PROGRAM.md	(d, w)	LANDS: the same `"kernel"` emitter as QUERY_INVENTORY.md row V5 (line 28002)
reports/TR4_SIZE_OF_THE_SPACE.md	SOLVE_KNUTH_PIN_SLOTS	LANDS: line 7899 is the knuth_pin_mask pair-index test; the env var that fills the mask is parsed elsewhere
scripts/doc_gates.sh	This read	HISTORICAL: names the header sentence at line 19 that carried a retracted phrase before ff804bb0; line 19 still holds that sentence, corrected, and the anchors on the line are that gate's own vocabulary
scripts/exec_lane.sh	--preflight	LANDS: line 4112 is the disk-IOPS pre-check PASS fprintf; the comment paraphrases its words with '...', so nothing is verbatim
scripts/exec_lane_verdict_gate.sh	disk_iops_pre_check	LANDS: line 4119 is the 'ERROR: projected fsync-wait' format string; the fixture below it is rendered output, not the format
scripts/tr12_repro.sh	$SOLVE	LANDS: line 37077 is the in-memory-only refusal `if (fkc->ooc != NULL)` (Opus UU repin, content-checked); the row describes it in prose only
scripts/tr12_repro.sh	$SOLVE	LANDS: line 20692 is the `n > KC_MEM_MAX_PAIRS` out-of-core switch (Opus UU repin, content-checked); same row
solve.py	KC_SCAN	LANDS: line 29314 is `if (ok[i] == 0)`, the unconditional tail-failure count; gate_fails is bumped under `if (strict)` just outside the +-2 window
solve.py	%s\tcd=%d\t	LANDS: line 38239 is the record-line emitter the comment cites; the cd= form it also names is the sibling at 38314
viz/report_figures.py	SOLVE_KNUTH_PIN_SLOTS	LANDS: the same knuth_pin_mask test as TR4 (line 7899)
viz/report_figures.py	N_total	LANDS: line 41140 is `if (v >= 1 && v <= 31) knuth_pin_mask |= ...`; the env name is read 4 lines above, outside +-2
viz/viz_kc_grammar.md	--kc-raw	LANDS: 28001-28010 is the `if (want_raw)` raw kernel-cell loop (Opus UU repin, content-checked); the flag itself is parsed elsewhere
PINS
)
ALL_PINS="${CITGATE_ALL_PINS-$ALL_PINS_DEFAULT}"

# THE --all-targets PIN TABLE (Q-791): <citing file> TAB <target> TAB <key> TAB <reason>, for stale
# citations into files OTHER than solve.c (solve.c's rows are the table above, reused as-is).
TARGET_PINS_DEFAULT=$(cat <<'PINS'
# file	target	key	reason
documentation/CRITIQUE.md	documentation/CRITIQUE.md	a few hours	LANDS: line 60 is the Gray-code C3 rate bound 'scoped to its sampler', the over-reach correction the note refers back to (self-reference)
documentation/CAMPAIGN_METHODOLOGY.md	documentation/HISTORY.md	origin/main	LANDS: HISTORY.md line 4158 is the line carrying the 8-hex UUID prefix `3620ba16-…` the sentence describes
documentation/CAMPAIGN_METHODOLOGY.md	documentation/HISTORY.md	origin/main	LANDS: HISTORY.md line 1907 carries the `d63bb25c…` UUID token the sentence describes
documentation/CAMPAIGN_METHODOLOGY.md	documentation/HISTORY.md	9a968fa2	LANDS: HISTORY.md line 5146-5147 carry the old/new pre-merge shard totals (43,876,464,466) the cell names
documentation/CITATIONS.md	documentation/CITATIONS.md	6a3feaaa	LANDS: line 401 is this section's preamble sentence (Suenaga ... initiated counting) that Q-127/Q-263 read; re-pinned by content 2026-09-25 (Q-791)
documentation/DEVELOPMENT.md	scripts/perf_bench.sh	--keep-vm	LANDS: the four explicit `teardown` call sites in perf_bench.sh (re-measured 2026-09-25, Q-791: four, not three); the miner's anchors are the teardown function's words
documentation/DEVELOPMENT.md	scripts/perf_bench.sh	--keep-vm	LANDS: the four explicit `teardown` call sites in perf_bench.sh (re-measured 2026-09-25, Q-791: four, not three); the miner's anchors are the teardown function's words
documentation/DEVELOPMENT.md	scripts/perf_bench.sh	--keep-vm	LANDS: the four explicit `teardown` call sites in perf_bench.sh (re-measured 2026-09-25, Q-791: four, not three); the miner's anchors are the teardown function's words
documentation/DEVELOPMENT.md	scripts/perf_bench.sh	--keep-vm	LANDS: the four explicit `teardown` call sites in perf_bench.sh (re-measured 2026-09-25, Q-791: four, not three); the miner's anchors are the teardown function's words
documentation/QUERY_INVENTORY.md	solve.py	PENDING	LANDS: solve.py line 13673 is `def atlas_emit_xa`, the XA consumer the ruling describes (re-pinned from line 12062ff, which pointed there at a19682b2)
documentation/QUERY_INVENTORY.md	solve.py	extrema	LANDS: the Q6 'per-distance-class mass, not per-(state,choice)' comment in solve.py (re-pinned 2026-09-25, Q-791); the anchors mined are the row's other words
documentation/QUERY_INVENTORY.md	solve.py	extrema	LANDS: the Q6 'per-distance-class mass, not per-(state,choice)' comment in solve.py (re-pinned 2026-09-25, Q-791); the anchors mined are the row's other words
documentation/QUERY_INVENTORY.md	viz/viz_kc_grammar.md	(d, w)	LANDS: viz_kc_grammar.md line 61-62 is where the new-pair category is stated to be undefined in TR-12 section 2 (re-pinned from line 44, Q-791)
documentation/QUERY_INVENTORY.md	scripts/tr12_repro.sh	TR12_Q7	LANDS: tr12_repro.sh line 3626 is `agg(){`, the helper definition the sentence names; the row's anchors are the two agg call sites (line 3640/line 3645, which land)
documentation/SOLUTIONS_FORMAT.md	runs/20260419_100T_d3_d128westus3/README.md	_10T_d3_d128westus3	LANDS: the run README's line 10 is 'Solver commit at enumeration launch'; the only mined anchor is a directory-name fragment
documentation/SOLVE_C_CLI.md	solve.py	--books-verify	LANDS: solve.py line 10496-10499 is the Goldenberg attribution block (re-pinned from line 9682-9685, Q-791)
documentation/SOLVE_C_CLI.md	documentation/CITATIONS.md	--books-verify	LANDS: CITATIONS.md line 2646 is the goldenberg1975 ledger anchor (re-pinned from line 1855, Q-791)
documentation/SOLVE_PY_CLI.md	solve.py	--tr8-dof-pool-draws	LANDS: solve.py line 1093-1096 writes results.json / RESULTS.md, the results writer the sentence means (re-pinned from line 1023, Q-791)
documentation/SOLVE_PY_CLI.md	solve.py	"timing-probe"	LANDS: the pool-seed use (line 901) and results writer (line 1093-1096) named in the re-pin note itself (Q-791)
documentation/SOLVE_PY_CLI.md	solve.py	"timing-probe"	LANDS: the pool-seed use (line 901) and results writer (line 1093-1096) named in the re-pin note itself (Q-791)
documentation/SOLVE_PY_CLI.md	documentation/DISTRIBUTIONAL_ANALYSIS.md	--joint-density	LANDS: DISTRIBUTIONAL_ANALYSIS.md line 217 opens the de-circularized two-dimension re-run the cell points to
documentation/VERIFY.md	documentation/CITATIONS.md	exact count	LANDS: CITATIONS.md line 416 and line 1501 carry 'validated estimates for C1-C5' beside the exact C1-C2-C4-C5 layer counts (re-pinned from line 346/line 964, Q-791)
documentation/VERIFY.md	documentation/CITATIONS.md	exact count	LANDS: CITATIONS.md line 416 and line 1501 carry 'validated estimates for C1-C5' beside the exact C1-C2-C4-C5 layer counts (re-pinned from line 346/line 964, Q-791)
documentation/VERIFY.md	documentation/DESCRIPTION_LENGTH.md	|C1–C7|	LANDS: DESCRIPTION_LENGTH.md line 77 is '|C1∩C4∩C5| = |C1∩C2∩C4∩C5| exactly. The C3 conditional remains sampled by design.'
reports/TR12_QUERY_PROGRAM.md	viz/viz_kc_grammar.md	(d, w)	LANDS: the same viz_kc_grammar.md line 61-62 category-undefined passage as QUERY_INVENTORY.md row V5 (Q-791)
reports/TR9_PRICING_THE_CONSTRAINTS.md	documentation/DESCRIPTION_LENGTH.md	 relaxation** of	LANDS: DESCRIPTION_LENGTH.md line 54 is the '+ C2 (no-5)' table row, the sibling cell (re-pinned from line 36, which it was at 6ffab778; Q-791)
reports/TR9_PRICING_THE_CONSTRAINTS.md	documentation/DESCRIPTION_LENGTH.md	 relaxation** of	LANDS: DESCRIPTION_LENGTH.md line 205-207 is the 2026-07-10 C2 refinement paragraph, the second sibling (re-pinned from line 127-129, Q-791)
scripts/doc_gates.sh	documentation/CORRECTIONS.md	quoted	LANDS: CORRECTIONS.md line 4146-4147 is the ledger's quotation of the retired 'maximum by construction' sentence (re-pinned from line 4121, where it was at b69f13f1; Q-791)
scripts/doc_gates.sh	reports/TR6_PARITY_SKELETON.md	at the time of the SAT work (×11,364),	LANDS: TR6:132-133 carry the qualifier, hard-wrapped across the two lines, so the verbatim fragment is on neither
scripts/doc_gates.sh	reports/TR4_SIZE_OF_THE_SPACE.md	sharpens further when S(6..8) land	LANDS: TR4:361 is the P34 wording ('sharpened by the 2026-07-05 S(6)-S(8) measurement'); the anchor is the retired wording the red test restores
scripts/doc_gates.sh	documentation/CLAIM_TO_ARTIFACT.md	canonical	LANDS: CLAIM_TO_ARTIFACT.md line 45 is the n=9 26,112 row (row 14; re-pinned from line 41, Q-791); 'canonical' is the word the defect removed
scripts/doc_gates.sh	documentation/PROJECT_OVERVIEW.md	_10T_d3_fresh	LANDS: PROJECT_OVERVIEW.md line 102 attributes 21,794,755 / 152,468,987 to d3 10T; the anchor is the log path, named elsewhere
scripts/doc_gates.sh	documentation/LARGE_SCALE_CAMPAIGNS.md	sort + dedup	LANDS: LARGE_SCALE_CAMPAIGNS.md line 1026 is 'There is no S at which you need code that does not exist' (re-pinned from line 995, Q-791)
scripts/exec_lane.sh	documentation/SOLVE_C_CLI.md	./solve	LANDS: SOLVE_C_CLI.md line 3545 quotes the pre-correction build line (re-pinned from line 2061, Q-791)
scripts/exec_lane.sh	documentation/CORRECTIONS.md	--follow	LANDS: CORRECTIONS.md line 3189 carries the bare `git log -S` fragment (re-pinned from line 3164, Q-791)
scripts/exec_lane_verdict_gate.sh	documentation/BRANCHES_EXPLAINED.md	--branch	LANDS: BRANCHES_EXPLAINED.md line 382 is '**All-branch enumeration** (`solve 0 64`)' (re-pinned from line 383, Q-791)
scripts/pre_commit_generated_gate.sh	roae.py	--seed	LANDS: roae.py line 23 is `_global_seed = None`, i.e. seeds nothing by default (re-pinned from line 22, Q-791)
scripts/tr12_repro.sh	documentation/GT_LADDER_FORMAT.md	--kc-t-check	LANDS: GT_LADDER_FORMAT.md line 297 is 'integrity checks: they constrain the FILES, not the shared'; this text is a row_skip REASON emitted into the goldens, so it is pinned, not reworded
scripts/tr12_repro.sh	documentation/GT_LADDER_FORMAT.md	--kc-t-check	LANDS: the same GT_LADDER_FORMAT.md line 297 sentence, in the sibling row_skip reason (goldens text)
scripts/tr12_repro.sh	scripts/tr12_repro.sh	by_class	LANDS: line 2978 is the F-5 D11 fix in row c_v1 (self-reference, re-pinned from line 2260, Q-791)
scripts/tr12_repro_gate.sh	scripts/tr12_repro_gate.sh	, which is pre_push_gate.sh's variable and is unset here --	LANDS: line 225/line 229 are the q2_witness leg's `./scripts/...` repo-relative paths, the idiom named (self-reference, re-pinned from line 306/line 318, Q-791)
scripts/tr12_repro_gate.sh	scripts/tr12_repro_gate.sh	, which is pre_push_gate.sh's variable and is unset here --	LANDS: line 225/line 229 are the q2_witness leg's `./scripts/...` repo-relative paths, the idiom named (self-reference, re-pinned from line 306/line 318, Q-791)
solve.py	tests.py	--kc-tdir	LANDS: tests.py line 6211 is a minimal `"gates": {"fails": 0}` fixture (re-pinned from line 5655, Q-791)
solve.py	documentation/SOLVE_C_CLI.md	KC_SCAN	LANDS: SOLVE_C_CLI.md line 2249-2250 is the corrected paragraph quoting the claim that this loader closed it (re-pinned from line 2238, Q-791)
solve.py	viz/viz_kc_field.md	layers	LANDS: viz_kc_field.md line 34 is 'Index the ordering by its 32 pair-slots', the published convention the comment quotes
tests.py	sat.py	--keep	LANDS: sat.py line 1854 is the `_run_tool(["d4", ...])` call (re-pinned from line 1823, Q-791); 'd4' is too short to mine
tests.py	solve.py	--rules	LANDS: solve.py line 1649-1657 is print_rules' docstring withdrawal plus the retired-banner comment (re-pinned from line 1581, Q-791)
PINS
)
TARGET_PINS="${CITGATE_TARGET_PINS-$TARGET_PINS_DEFAULT}"

_run_all() { # $1 root  $2 base ref  $3 base-explicit (1|"")  $4 pins  $5 all-targets (1|"")  $6 target pins
  ROOT="$1" BASE="$2" BASE_EXPLICIT="$3" PINS="$4" ALLT="${5:-}" TPINS="${6:-}" python3 - <<'PYEOF'
import os, re, subprocess, sys
from collections import Counter, defaultdict
root, base, base_explicit, pins_raw = (os.environ[k] for k in ("ROOT", "BASE", "BASE_EXPLICIT", "PINS"))
allt, tpins_raw = os.environ["ALLT"] == "1", os.environ["TPINS"]
try:
    os.chdir(root)
except OSError as e:
    print("ERROR cannot enter %s: %s" % (root, e)); sys.exit(0)

def git(args):
    r = subprocess.run(["git"] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return (r.returncode, r.stdout.decode("utf-8", "replace"))

rc, _ = git(["rev-parse", "--is-inside-work-tree"])
if rc != 0:
    print("ERROR %s is not a git work tree" % root); sys.exit(0)
try:
    open("solve.c", encoding="utf-8", errors="replace").close()
except OSError as e:
    print("ERROR unreadable solve.c: %s" % e); sys.exit(0)

# ---- targets (Q-791) ------------------------------------------------------------------------
# Plain --all-files reads `solve.c:N` only. --all-targets reads `<file>:N` for EVERY tracked file,
# resolving the cited name against `git ls-files`: an exact tracked path; else the path taken
# relative to the citing file's directory; else the unique tracked file whose path ends in
# `/<name>`; else, among several, the one in the citing file's own directory. A name that
# resolves to nothing (a private-repo file, a host:port, `e.g:`) is counted as `unresolved`; one
# that resolves to several is counted as `ambiguous`. Both counts are printed, never silent.
rc, lsf = git(["ls-files", "-z"])
tracked = [x for x in lsf.split("\0") if x]
tracked_set = set(tracked)
by_base = defaultdict(list)
for x in tracked:
    by_base[os.path.basename(x)].append(x)
# Under --all-targets a mined candidate that is the name of a tracked file (`SOLVE_SUMMARY`,
# `tr12_repro.sh`, `CITATIONS`) is how prose POINTS at a document, never what sits on the cited
# line; left in, it lands on any line that mentions the other file and fails on every other one.
bases = set(by_base)
stems = {os.path.splitext(b)[0] for b in by_base if len(os.path.splitext(b)[0]) >= 5}
_res = {}
def resolve(name, citer):
    k = (name, os.path.dirname(citer))
    if k in _res:
        return _res[k]
    n = name[2:] if name.startswith("./") else name
    r = None
    if n in tracked_set:
        r = n
    else:
        rel = os.path.normpath(os.path.join(os.path.dirname(citer), n))
        if rel in tracked_set:
            r = rel
        else:
            c = [x for x in by_base.get(os.path.basename(n), []) if x.endswith("/" + n)]
            if len(c) == 1:
                r = c[0]
            elif len(c) > 1:
                same = [x for x in c if os.path.dirname(x) == os.path.dirname(citer)]
                r = same[0] if len(same) == 1 else "?ambiguous"
    _res[k] = r
    return r

_tsrc = {}
def tsrc(t):
    """(lines, text) of a target, or None when it is unreadable or binary."""
    if t not in _tsrc:
        try:
            b = open(t, "rb").read()
            _tsrc[t] = None if b"\0" in b[:65536] else (b.decode("utf-8", "replace").split("\n"),
                                                       b.decode("utf-8", "replace"))
        except OSError:
            _tsrc[t] = None
    return _tsrc[t]

# ---- the citation grammar -------------------------------------------------------------------
# `solve.c:N`, `solve.c:N-M` (en dash too, and the abbreviated `:18858-76`), and a bare `:N`
# continuation, which belongs to the most recent `<name>.<ext>:N` citation on the same line and
# counts only when that one is solve.c ("(solve.c:38254, :41422)", "solve.c:23844/:24475").
TOK = re.compile(
    r'(?P<file>(?<![\w.\-])[\w\-./]*[\w\-]\.[A-Za-z]{1,5}):(?P<a>\d+)(?:\s?[-–]\s?(?P<b>\d+))?(?!\d|\.\d)'
    r'|(?:(?<=[\s(`,/;])|^):(?P<ca>\d+)(?:\s?[-–]\s?(?P<cb>\d+))?(?!\d|\.\d|:)')
SHA = r'(?=[0-9a-f]*[a-f])(?=[0-9a-f]*[0-9])[0-9a-f]{7,40}'
TGT = r'[\w./-]+\.[A-Za-z]{1,5}' if allt else r'solve\.c'
LINE_EXCL = [
    ("codex-id",  re.compile(r'Codex v\d+\S*\s+`?' + TGT + ':')),
    ("rev-pin",   re.compile(r'(?:\bat|@)\s*`?(?:HEAD\s+)?' + SHA + r'\b')),
    ("git-show",  re.compile(r'git show\s+\S*:' + TGT + r'|\b' + SHA + ':' + TGT)),
    ("dated-row", re.compile(r'^\s*\|\s*\**\s*(?:v\d+(?:\.\d+)+|\d{4}-\d{2}-\d{2})\b'
                             r'|\t[^\t]*\b(?:Retracted|Added|Corrected|Withdrawn)\s+\d{4}-\d{2}-\d{2}')),
]
EXCL_PATH = re.compile(r'^(?:documentation/(?:CORRECTIONS|HISTORY)\.md|documentation/CORRECTIONS_INVENTORY\.tsv|reports/evidence/)')

def span(a, b):
    a = int(a)
    if b is None:
        return a, a
    bs = b; b = int(b)
    if b < a and len(bs) < len(str(a)):          # abbreviated range: 18858-76 -> 18858-18876
        b = int(str(a)[:len(str(a)) - len(bs)] + bs)
    return min(a, b), max(a, b)

excluded = Counter()
implied_n = Counter()      # bare `(:N)` citations whose file was IMPLIED: [True] = self, [False] = context
def is_target(t):
    return t is not None and not t.startswith("?") and (allt or t == "solve.c")
FNAME = re.compile(r'(?<![\w.\-])([\w\-./]*[\w\-]\.(?:c|h|py|sh|md|tsv|txt|json|lean|pin))(?![\w])')
def implied(line, pos, citer, prev):
    """--all-targets only: the file a bare `(:N)` / `` `:N` `` with no `<file>:N` before it on its
    line refers to. The last resolvable file NAME earlier on the same line ("<gate> uses this
    idiom (:N)"); else the last `<file>:N` CITATION in the preceding lines of the same
    paragraph (up to 15, never across a blank line) (a comment block continues a citation chain across its wrap: a file-qualified
    number ends one line and a bare parenthesised one opens the next); else the citing file
    ITSELF -- the self-reference shape ("fixed next door (:N)" in the battery), which Q-791 found
    stale and which no grammar read. A mere file NAME on an earlier line does not count: prose
    names files it is not citing, and measured, that rule mis-assigned self-references."""
    names = [m.group(1) for m in FNAME.finditer(line[:pos])]
    if names:                    # the LAST name wins; if it resolves to nothing, neither does this
        return resolve(names[-1], citer)
    for text in prev:
        files = [m.group("file") for m in TOK.finditer(text) if m.group("file") is not None]
        if files:
            return resolve(files[-1], citer)
    return citer
# A revision pin excludes only the citation it is written against (within 40 characters either
# side), not every citation on the line (Q-791): one `solve.py:N@<sha>` inside a long table row
# must not hide that row's live `solve.c:N` citations. MEASURED on the batch 1-8 tree: the plain
# --all-files counts are unchanged by this narrowing (238 / 218 checked / 18 stale / rev-pin 3).
REVPIN = dict(LINE_EXCL)["rev-pin"]
# A Codex batch finding locator -- `(BATCH A03 row 22, SPECIFICATION.md:173)`, `(batch 11 row 6,
# DEVELOPMENT.md:47 + ...)`, `Codex A01 row 32 (PROJECT_OVERVIEW.md:96/:105)` -- possibly wrapped onto
# the next line, names the line in CODEX'S snapshot: an identifier, like `Codex v2 solve.c:N` above.
BATCHROW = re.compile(r'(?:\((?:BATCH|batch) A?\d+ row \d+,|\bCodex A\d+ row \d+ \()[^)]*$')
BTFILE = re.compile(r'`([^`\s]+\.[A-Za-z]{1,5})`:(?=\d)')
MDLINK = re.compile(r'\[[^\]\n]*\]\(`?([^)\s#`]+\.[A-Za-z]{1,5})`?\):(?=\d)')
def cites(line, citer, prev=()):
    """(target, lo, hi, text) for every live citation on the line; exclusions counted."""
    if allt:     # a markdown link glued to its line number, `[CITATIONS.md](CITATIONS.md):1855`, is the
        line = MDLINK.sub(lambda m: " " + m.group(1) + ":", line)   # same citation: read it as one;
        line = BTFILE.sub(lambda m: " " + m.group(1) + ":", line)   # so is a backticked name, `x.out`:14
    out, cur, seen, pinned = [], None, False, False
    for m in TOK.finditer(line):
        if m.group("file") is not None:
            seen = True          # a file-qualified number, resolvable or not, owns what follows it
            pinned = False
        elif allt and pinned:    # `HISTORY.md:2014@<sha>, :2268, :4784` -- the continuations are read
            excluded["rev-inherit"] += 1; continue      # at the revision their head names, not HEAD
        if (allt and not seen and m.group("file") is None
                and (line[max(0, m.start() - 1):m.start()] in ("(", "`")
                     or re.search(r'\b(?:at|see) $', line[max(0, m.start() - 4):m.start()]))):
            cur = implied(line, m.start(), citer, list(prev))
            seen = True
        if m.group("file") is not None:
            f = m.group("file")
            if allt:
                cur = resolve(f, citer)
                if cur is None:
                    excluded["unresolved"] += 1
                elif cur == "?ambiguous":
                    excluded["ambiguous"] += 1
            else:
                cur = "solve.c" if (f == "solve.c" or f.endswith("/solve.c")) else f
            if not is_target(cur):
                continue
            if re.search(SHA + r':$', line[:m.start()]):
                excluded["git-show"] += 1; pinned = True; continue
            lo, hi = span(m.group("a"), m.group("b"))
        else:
            if not is_target(cur):
                continue
            lo, hi = span(m.group("ca"), m.group("cb"))
        if (BATCHROW.search(line[:m.start()])
                or (prev and BATCHROW.search(prev[0]) and ")" not in line[:m.start()])):
            excluded["codex-batch"] += 1; continue
        if line[m.end():m.end() + 1] == "@" or line[max(0, m.start() - 1):m.start()] == "@":
            excluded["at-N"] += 1; pinned = m.group("file") is not None; continue
        if allt and tsrc(cur) is None:
            excluded["binary-target"] += 1; continue
        if REVPIN.search(line[max(0, m.start() - 40):m.end() + 40]):
            excluded["rev-pin"] += 1; pinned = m.group("file") is not None; continue
        out.append((cur, lo, hi, m.group(0).strip()))
        if m.group("file") is None and not re.search(r'[\w\-]\.[A-Za-z]{1,5}:\d', line[:m.start()]):
            implied_n[cur == citer] += 1
            if os.environ.get("CITGATE_PINROWS") == "1":   # audit trail: which file each bare :N was read as
                sys.stderr.write("PINROW\tIMPLIED\t%s -> %s\t%s\n" % (citer, cur, m.group(0).strip()))
    if out:
        for cls, rx in LINE_EXCL:
            if cls == "rev-pin":
                continue         # judged per citation above
            if rx.search(line):
                excluded[cls] += len(out); return []
    return out

# ---- the population: tracked text files that carry a solve.c:N ------------------------------
rc, out = git(["grep", "-I", "-l", "-E", r"\.[A-Za-z]{1,5}`?\)?:[0-9]|[(`]:[0-9]" if allt else r"solve\.c:[0-9]"])
if rc not in (0, 1):
    print("ERROR git grep failed (rc=%d)" % rc); sys.exit(0)
files = []
for p in out.split("\n"):
    if not p:
        continue
    if EXCL_PATH.search(p):
        excluded["path"] += 1; continue
    files.append(p)

# ---- LEG A: the shift map ---------------------------------------------------------------------
# One map per changed TARGET (solve.c alone without --all-targets). `thunks[t]` is t's hunk list.
thunks, legA_note, changed = {}, "", set()
rc, _ = git(["rev-parse", "--verify", "-q", base + "^{commit}"])
if rc != 0:
    if base_explicit:
        print("ERROR base ref %r does not resolve to a commit" % base); sys.exit(0)
    legA_note = "base %s unresolvable -- leg A measured nothing" % base
else:
    rc, names = git(["diff", "--name-only", "--no-renames", base])
    if rc != 0:
        print("ERROR git diff --name-only %s failed" % base); sys.exit(0)
    changed = set(x for x in names.split("\n") if x)
    for t in sorted(changed if allt else {"solve.c"} & changed):
        rc, d = git(["diff", "-U0", "--no-color", "--no-ext-diff", "--no-renames", base, "--", t])
        if rc != 0:
            print("ERROR git diff %s -- %s failed" % (base, t)); sys.exit(0)
        h = [tuple(int(x) if x != '' else 1 for x in hh) for hh in
             re.findall(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@', d, re.M)]
        if h:
            thunks[t] = h
    if not thunks:
        legA_note = ("no tracked file" if allt else "solve.c") + \
                    " is changed against %s -- nothing moved, leg A vacuous" % base
hunks = bool(thunks)

def lmap(n, t):
    """old line n of target t -> new line, or None when n lies inside a rewritten hunk."""
    delta = 0
    for os_, ol, ns, nl in thunks.get(t, ()):
        if ol == 0:                      # pure insertion AFTER old line os_
            if n <= os_: return n + delta
            delta += nl
        else:
            if n < os_: return n + delta
            if n < os_ + ol: return None
            delta += nl - ol
    return n + delta

def candidates(line, tname="solve.c"):
    out = set()
    for m in re.finditer(r'`([^`\n]{1,120})`', line):
        frag = m.group(1)
        for w in re.findall(r'--[a-z0-9][a-z0-9-]{2,}|[A-Za-z_][A-Za-z0-9_]*', frag):
            if w.startswith("--") or (len(w) >= 5 and ("_" in w or w.isupper()
                                                      or re.search(r'[a-z][A-Z]', w))):
                out.add(w)
        f = frag.strip()
        if (len(f) >= 6 and not re.search(r'solve\.c:\d', f) and not re.fullmatch(r'[:\d\s,\-–]+', f)
                and not re.fullmatch(r'[\w./-]+\.(?:c|h|md|py|sh|tsv|txt|json)', f)):   # not a bare file name
            out.add(f)                   # a verbatim code fragment: `argc < 5`, `total_fail == 0`
    out |= set(re.findall(r'"([^"\n]{6,80})"', line))
    out |= set(re.findall(r'"([^"\n]{12,80})$', line, re.M))    # a quoted literal the line wrap cut open
    out |= set(re.findall(r'\b(SOLVE_[A-Z0-9_]{2,})\b', line))
    out |= set(re.findall(r'(?<![\w-])(--[a-z0-9][a-z0-9-]{2,})', line))
    out |= {w for w in re.findall(r'\b([A-Za-z][A-Za-z0-9]*_[A-Za-z0-9_]+)\b', line) if len(w) >= 5}
    out |= set(re.findall(r'(?<![\w])(_[a-z][a-z0-9]*(?:_[a-z0-9]+)*_)(?![\w])', line))   # `_merged_`
    out |= set(re.findall(r'\b((?=[0-9a-f]*[a-f])(?=[0-9a-f]*\d)[0-9a-f]{8,64})\b', line))  # a sha literal
    # A trailing `_` marks a wildcard stem (`SOLVE_` for SOLVE_*), never a symbol -- unless the name
    # also STARTS with one, which is the `_merged_` directory-name shape.
    stem = os.path.splitext(os.path.basename(tname))[0]
    return {w for w in out if w != stem and w != "solve" and "solve.c:" not in w
            and not (allt and (w in stems or w in bases))     # a FILE NAME is a pointer, not an anchor
            and not re.search(re.escape(os.path.basename(tname)) + r':\d', w)
            and (not w.endswith("_") or w.startswith("_"))}

def context(lines, li, ismd):
    """The citing line plus its paragraph neighbours (<= 3 lines each way, never across a blank
    line). Hard-wrapped prose puts the symbol on the line BEFORE the number as often as on the
    same line (`...\n  `int fail_c1 ...` (`solve.c:43263-43264`)`), and a comment block in a
    script is one sentence spread over several `#` lines. A markdown TABLE ROW is its own unit:
    the next row is a different claim, so a table row takes no neighbours; nor does a heading."""
    line = lines[li - 1]
    if line.lstrip().startswith("|"):
        return line
    out = [line]
    for step in (-1, 1):
        j = li - 1 + step
        while 0 <= j < len(lines) and abs(j - (li - 1)) <= 3:
            t = lines[j]
            if not t.strip() or t.lstrip().startswith("|") or (ismd and re.match(r'#{1,6} ', t)):
                break
            out.append(t); j += step
    return "\n".join(out)

LEGB = re.compile(r'\.(?:md|py|sh)$')
shift, inhunk, stale, cited = [], [], [], set()
totA = totB = checked = 0
for p in files:
    try:
        lines = open(p, encoding="utf-8", errors="replace").read().split("\n")
    except OSError:
        continue
    base_lines = None
    if hunks and p in changed:
        rc, bt = git(["show", "%s:%s" % (base, p)])
        base_lines = Counter(bt.split("\n")) if rc == 0 else Counter()
    heading, isb, ismd = "", bool(LEGB.search(p)), p.endswith(".md")
    for li, line in enumerate(lines, 1):
        if ismd and line.startswith("#"):
            heading = line
        prev = []
        if True:
            j = li - 2
            while j >= 0 and len(prev) < 15 and lines[j].strip():
                prev.append(lines[j]); j -= 1
        cs_line = cites(line, p, prev)
        if not cs_line:
            continue
        # LEG A
        if hunks and (base_lines is None or base_lines[line] > 0):
            for tg, lo, hi, t in cs_line:
                totA += 1
                ml, mh = lmap(lo, tg), lmap(hi, tg)
                tt = t if tg == "solve.c" else "%s [%s]" % (t, tg)
                if ml is None or mh is None:
                    inhunk.append("%s:%d %s" % (p, li, tt))
                elif ml != lo or mh != hi:
                    shift.append("%s:%d %s -> map %s" % (p, li, tt, ml if lo == hi else "%d-%d" % (ml, mh)))
        # LEG B
        if not isb:
            continue
        ctx = context(lines, li, ismd)
        for tg, lo, hi, t in cs_line:
            totB += 1
            cited.add(tg)
            src, srctext = tsrc(tg)
            cands = candidates(ctx, tg) | (candidates(heading, tg) if ismd else set())
            cands = {c for c in cands if c in srctext}
            if not cands:
                continue
            checked += 1
            win = "\n".join(src[max(0, lo - 3):hi + 2])
            if hi > len(src) or not any(c in win for c in cands):
                stale.append((p, tg, li, t, sorted(cands)[0], sorted(cands)))

# Pins are keyed (citing file, target, anchor key). The solve.c table has 3 columns (its target is
# solve.c); the --all-targets table has 4: file TAB target TAB key TAB reason.
pins = Counter()
for raw, ncol in ((pins_raw, 3), (tpins_raw if allt else "", 4)):
    for r in raw.split("\n"):
        if not r.strip() or r.lstrip().startswith("#"):
            continue
        f = r.split("\t")
        if len(f) < ncol or not f[ncol - 1].strip():
            print("ERROR malformed pin row (need %s TAB reason): %r"
                  % ("file TAB key" if ncol == 3 else "file TAB target TAB key", r)); sys.exit(0)
        pins[(f[0], "solve.c", f[1]) if ncol == 3 else (f[0], f[1], f[2])] += 1

if totB == 0 or checked == 0:
    print("ERROR leg B found %d citation(s), %d checkable -- measured nothing" % (totB, checked)); sys.exit(0)

print(("COUNT all-targets cited-targets=%d implied-self=%d implied-context=%d\n"
       % (len(cited), implied_n[True], implied_n[False]) if allt else "")
      + "COUNT files=%d legB total=%d checked=%d stale=%d uncheckable=%d pinned=%d"
      % (len(files), totB, checked, len(stale), totB - checked, sum(pins.values())))
print("COUNT excluded " + (" ".join("%s=%d" % kv for kv in sorted(excluded.items())) or "none"))
if legA_note:
    print("COUNT legA " + legA_note)
else:
    print("COUNT legA base=%s files-moved=%d hunks=%d unmoved-citations=%d shifted=%d inhunk=%d"
          % (base, len(thunks), sum(len(v) for v in thunks.values()), totA, len(shift), len(inhunk)))
for s in shift:
    print("SHIFT " + s)
for s in inhunk:
    print("INHUNK " + s)
seen = Counter((p, tg, k) for p, tg, _, _, k, _ in stale)
for p, tg, li, t, k, cs in stale:
    print("%s %s:%d %s%s names %s" % ("OPEN" if seen[(p, tg, k)] <= pins[(p, tg, k)] else "NEW",
                                      p, li, t, "" if tg == "solve.c" else " [%s]" % tg, ",".join(cs[:4])))
    if os.environ.get("CITGATE_PINROWS") == "1":      # a pin-table row, key verbatim (keys may hold commas)
        sys.stderr.write("PINROW\t%s\t%s\t%s\t%s:%d %s\n" % (p, tg, k, p, li, t))
bad = []
if shift:
    bad.append("leg A: %d citation(s) left behind by a %s shift" % (len(shift), "target-file" if allt else "solve.c"))
new = sorted(k for k in seen if seen[k] > pins[k])
gone = sorted(k for k in pins if seen[k] < pins[k])
if new:
    bad.append("leg B: stale citation(s) beyond the pin: " + ", ".join("%s->%s[%s]" % k for k in new))
if gone:
    bad.append("leg B: pinned stale citation(s) no longer stale -- TIGHTEN the pin: "
               + ", ".join("%s->%s[%s]" % k for k in gone))
if bad:
    for b in bad:
        print("VERDICT FAIL " + b)
else:
    print("VERDICT PASS leg A %s; leg B %d stale, all pinned exactly"
          % ("vacuous" if legA_note else "0 shifted", len(stale)))
PYEOF
}

# NEVER pipe a producer into `grep -q` under `set -o pipefail`: grep -q exits at the first match,
# SIGPIPEs the producer, the pipeline status becomes 141, and a MATCH reads as NO MATCH. Capture
# to a file first, then match the file.
OUT=$(mktemp); trap 'rm -f "$OUT"' EXIT

verdict_of() { # $1..$4 -> echoes PASS|FAIL|ERROR
  _run "$1" "$2" "$3" "$4" >"$OUT" 2>&1
  if grep -q '^ERROR ' "$OUT"; then echo ERROR
  elif grep -q '^VERDICT PASS ' "$OUT"; then echo PASS
  else echo FAIL; fi
}

verdict_all() { # $1 root $2 base $3 base-explicit $4 pins [$5 all-targets $6 target pins] -> PASS|FAIL|ERROR
  _run_all "$1" "$2" "$3" "$4" "${5:-}" "${6:-}" >"$OUT" 2>&1
  if grep -q '^ERROR ' "$OUT"; then echo ERROR
  elif grep -q '^VERDICT PASS ' "$OUT"; then echo PASS
  else echo FAIL; fi
}
print_all() { # the --all-files report; a run that printed no verdict at all (a crash) shows its tail
  sed -n 's/^COUNT /  [cite] /p;s/^SHIFT /  [SHIFT] /p;s/^INHUNK /  [inhunk] /p;s/^NEW /  [NEW] /p;s/^OPEN /  [open] /p;s/^VERDICT FAIL /  [FAIL] /p;s/^VERDICT PASS /  [ok] /p;s/^ERROR /  [ERROR] /p;/^PINROW\t/p' "$OUT"
  grep -q '^VERDICT \|^ERROR ' "$OUT" || tail -5 "$OUT" | sed 's/^/  [crash] /'
}

if [ "${1:-}" = "--selftest" ]; then
  # RED-TEST IN BOTH DIRECTIONS. The isolating case is ONE DIGIT of ONE citation: legs A and B
  # share byte-identical source and doc except that B's citation says 4 where A's says 3. If the
  # gate cannot tell those apart it is checking nothing, and a wrong line number is exactly the
  # defect it exists to catch.
  W=$(mktemp -d); trap 'rm -f "$OUT"; rm -rf "$W"' EXIT
  printf 'int a;\nint b;\nstatic int sub_ckpt_interval_sec = 60;\nint c;\n' >"$W/s.c"
  # (The line number is a printf ARGUMENT so this file does not itself carry a literal citation
  # for --all-files to read against the real solve.c.)
  printf 'Row: `SOLVE_CKPT_INTERVAL` is `sub_ckpt_interval_sec` (solve.c:%d).\n' 3 >"$W/a.md"
  printf 'Row: `SOLVE_CKPT_INTERVAL` is `sub_ckpt_interval_sec` (solve.c:%d).\n' 4 >"$W/b.md"
  printf 'No citations here at all.\n' >"$W/c.md"
  rc=0
  a=$(verdict_of "$W/a.md" "$W/s.c" 0 "")           # lands  -> PASS
  b=$(verdict_of "$W/b.md" "$W/s.c" 0 "")           # off by one line -> FAIL
  c=$(verdict_of "$W/c.md" "$W/s.c" 0 "")           # measured nothing -> ERROR
  d=$(verdict_of "$W/b.md" "$W/s.c" 1 "sub_ckpt_interval_sec")  # same defect, pinned -> PASS
  [ "$a" = PASS  ] || { echo "  [gate] leg A (correct citation) gave $a, want PASS"; rc=1; }
  [ "$b" = FAIL  ] || { echo "  [gate] leg B (citation +1 line) gave $b, want FAIL"; rc=1; }
  [ "$c" = ERROR ] || { echo "  [gate] leg C (no citations) gave $c, want ERROR"; rc=1; }
  [ "$d" = PASS  ] || { echo "  [gate] leg D (ratchet pins the known defect) gave $d, want PASS"; rc=1; }
  [ "$rc" = 0 ] && echo "  [ok] red-test: A=PASS B=FAIL C=ERROR D=PASS (A vs B differ by one digit)"

  # --all-files legs, on a throwaway git repo (leg A needs a real base commit and a real diff).
  # Fixture solve.c: `alpha_beta_gamma` on line 3, `kc_widget_count` on line 8, 12 lines.
  # doc.md line 1 is anchored (leg B checks it); line 3 names nothing, so ONLY leg A can see it.
  R="$W/r"; mkdir -p "$R"
  G() { git -C "$R" -c user.name=selftest -c user.email=selftest@invalid "$@" >/dev/null 2>&1; }
  G init -q
  mk_src() { : >"$R/solve.c"; for i in $(seq 1 12); do
      case $i in 3) echo 'int alpha_beta_gamma;';; 8) echo 'static int kc_widget_count = 0;';;
                 *) echo "int filler_$i;";; esac >>"$R/solve.c"; done; }
  mk_src
  L1='The counter `kc_widget_count` lives at solve.c:%d.\n'
  L2='\nSee also solve.c:%d for the rest.\n'   # a blank line apart: its own paragraph
  printf "$L1$L2" 8 10 >"$R/doc.md"
  G add -A; G commit -q -m base
  e=$(verdict_all "$R" HEAD "" "")            # clean committed tree: A vacuous, B lands -> PASS
  # +3 lines after line 8: solve.c:8 keeps its anchor (leg B green), solve.c:10 is now line 13.
  { head -8 "$R/solve.c"; printf 'int ins_1;\nint ins_2;\nint ins_3;\n'; tail -n +9 "$R/solve.c"; } >"$R/s2"
  mv "$R/s2" "$R/solve.c"
  f=$(verdict_all "$R" HEAD "" ""); fo=$(cat "$OUT")
  printf "$L1$L2" 8 13 >"$R/doc.md"        # the same change moves the citation -> PASS
  g=$(verdict_all "$R" HEAD "" "")
  printf "$L1"'Pinned at 5c29683f: see solve.c:%d.\n' 8 10 >"$R/doc.md"   # a revision pin is excluded
  k=$(verdict_all "$R" HEAD "" "")
  mk_src; G add -A; G commit -q -m restore
  sed -i 's/kc_widget_count/alpha_beta_gamma/' "$R/doc.md"   # ONE mutated anchor (exists at :3)
  h=$(verdict_all "$R" HEAD "" "")
  i=$(verdict_all "$R" HEAD "" "$(printf 'doc.md\talpha_beta_gamma\tselftest pin')")
  printf "$L1$L2" 8 10 >"$R/doc.md"        # repaired, but the pin was left behind -> FAIL
  j=$(verdict_all "$R" HEAD "" "$(printf 'doc.md\talpha_beta_gamma\tselftest pin')")
  x=$(verdict_all "$R" no-such-ref-q786 1 "")   # an explicit base that does not resolve -> ERROR
  printf 'No citations.\n' >"$R/doc.md"
  y=$(verdict_all "$R" HEAD "" "")            # nothing to measure -> ERROR
  [ "$e" = PASS ]  || { echo "  [gate] leg E (--all-files, clean tree) gave $e, want PASS"; rc=1; }
  [ "$f" = FAIL ]  || { echo "  [gate] leg F (--all-files, solve.c +3 under an unmoved citation) gave $f, want FAIL"; rc=1; }
  grep -qx 'SHIFT doc.md:3 solve.c:10 -> map 13' <<<"$fo" \
                   || { echo "  [gate] leg F did not print 'SHIFT doc.md:3 solve.c:10 -> map 13'"; rc=1; }
  grep -q '^NEW ' <<<"$fo" && { echo "  [gate] leg F: leg B fired too, so F does not isolate leg A"; rc=1; }
  [ "$g" = PASS ]  || { echo "  [gate] leg G (--all-files, citation moved in the same change) gave $g, want PASS"; rc=1; }
  [ "$k" = PASS ]  || { echo "  [gate] leg K (--all-files, 'at <sha>' revision pin) gave $k, want PASS"; rc=1; }
  [ "$h" = FAIL ]  || { echo "  [gate] leg H (--all-files, one mutated anchor) gave $h, want FAIL"; rc=1; }
  [ "$i" = PASS ]  || { echo "  [gate] leg I (--all-files, the same defect pinned) gave $i, want PASS"; rc=1; }
  [ "$j" = FAIL ]  || { echo "  [gate] leg J (--all-files, pin outlived its defect) gave $j, want FAIL"; rc=1; }
  [ "$x" = ERROR ] || { echo "  [gate] leg X (--all-files, unresolvable --base) gave $x, want ERROR"; rc=1; }
  [ "$y" = ERROR ] || { echo "  [gate] leg Y (--all-files, no citation) gave $y, want ERROR"; rc=1; }
  [ "$rc" = 0 ] && echo "  [ok] red-test --all-files: E=PASS F=FAIL(shift, leg A alone) G=PASS K=PASS H=FAIL I=PASS J=FAIL X=ERROR Y=ERROR"

  # --all-targets legs (Q-791), on a second throwaway repo whose cited TARGET is a script, not
  # solve.c. helper.sh: `widget_total() {` on line 3, `}` on line 5, and on line 6 a SELF-reference
  # `(:N)` back to line 3 -- the bare shape tr12_repro.sh used and no grammar read. doc2.md cites
  # helper.sh twice: line 3 anchored (leg B can check it), line 5 not (only leg A can see it).
  # (Every number is a printf ARGUMENT, so this file carries no literal citation of its own.)
  R2="$W/r2"; mkdir -p "$R2"
  G2() { git -C "$R2" -c user.name=selftest -c user.email=selftest@invalid "$@" >/dev/null 2>&1; }
  G2 init -q
  printf 'static int kc_widget_count;\n' >"$R2/solve.c"
  mk_h() { { printf "$1"; printf '#!/bin/sh\n# filler\nwidget_total() {\n  echo 0\n}\n# the function above (:%d) is the only one\n' "$2"; } >"$R2/helper.sh"; }
  D2='The counter `kc_widget_count` lives at solve.c:%d.\n\nThe function `widget_total` is at helper.sh:%d.\n\nSee also helper.sh:%s for its end.\n'
  mk_h '' 3; printf "$D2" 1 3 5 >"$R2/doc2.md"
  G2 add -A; G2 commit -q -m base
  m0=$(verdict_all "$R2" HEAD "" "" 1 "")          # clean committed tree -> PASS
  mk_h '# ins 1\n# ins 2\n' 3                      # +2 lines at the TOP of helper.sh; nothing else moves
  m1=$(verdict_all "$R2" HEAD "" "" "" "")         # plain --all-files never reads helper.sh -> PASS
  m2=$(verdict_all "$R2" HEAD "" "" 1 ""); mo=$(cat "$OUT")   # --all-targets -> FAIL, leg A
  mk_h '# ins 1\n# ins 2\n' 5; printf "$D2" 1 5 7 >"$R2/doc2.md"   # the same change moves all three
  m3=$(verdict_all "$R2" HEAD "" "" 1 "")
  mk_h '# ins 1\n# ins 2\n' 5; printf "$D2" 1 5 "5@$(git -C "$R2" rev-parse --short=12 HEAD)" >"$R2/doc2.md"
  m4=$(verdict_all "$R2" HEAD "" "" 1 "")          # `helper.sh:N@<sha>` names that revision -> PASS
  printf "$D2" 1 5 7 >"$R2/doc2.md"; G2 add -A; G2 commit -q -m moved
  printf "$D2" 1 9 7 >"$R2/doc2.md"                # ONE digit: the anchored citation now misses
  m5=$(verdict_all "$R2" HEAD "" "" 1 "")
  m6=$(verdict_all "$R2" HEAD "" "" 1 "$(printf 'doc2.md\thelper.sh\twidget_total\tselftest pin')")
  printf "$D2" 1 5 7 >"$R2/doc2.md"                # repaired, pin left behind -> FAIL
  m7=$(verdict_all "$R2" HEAD "" "" 1 "$(printf 'doc2.md\thelper.sh\twidget_total\tselftest pin')")
  [ "$m0" = PASS ] || { echo "  [gate] leg M0 (--all-targets, clean tree) gave $m0, want PASS"; rc=1; }
  [ "$m1" = PASS ] || { echo "  [gate] leg M1 (plain --all-files over a helper.sh shift) gave $m1, want PASS"; rc=1; }
  [ "$m2" = FAIL ] || { echo "  [gate] leg M2 (--all-targets, helper.sh +2 under unmoved citations) gave $m2, want FAIL"; rc=1; }
  for want in 'SHIFT doc2.md:5 helper.sh:5 [helper.sh] -> map 7' 'SHIFT helper.sh:8 :3 [helper.sh] -> map 5'; do
    grep -qxF "$want" <<<"$mo" || { echo "  [gate] leg M2 did not print '$want'"; rc=1; }
  done
  [ "$m3" = PASS ] || { echo "  [gate] leg M3 (--all-targets, citations moved in the same change) gave $m3, want PASS"; rc=1; }
  [ "$m4" = PASS ] || { echo "  [gate] leg M4 (--all-targets, revision-pinned citation) gave $m4, want PASS"; rc=1; }
  [ "$m5" = FAIL ] || { echo "  [gate] leg M5 (--all-targets, one-digit anchor miss) gave $m5, want FAIL"; rc=1; }
  [ "$m6" = PASS ] || { echo "  [gate] leg M6 (--all-targets, the same defect pinned) gave $m6, want PASS"; rc=1; }
  [ "$m7" = FAIL ] || { echo "  [gate] leg M7 (--all-targets, pin outlived its defect) gave $m7, want FAIL"; rc=1; }
  if [ "$rc" = 0 ]; then echo "  [ok] red-test --all-targets: M0=PASS M1=PASS(plain blind) M2=FAIL(shift incl. self-ref) M3=PASS M4=PASS(@sha) M5=FAIL M6=PASS M7=FAIL"
                         echo "CITATION_LINE_GATE=PASS"; exit 0
  else echo "CITATION_LINE_GATE=FAIL"; exit 40; fi
fi

if [ "${1:-}" = "--all-files" ]; then
  shift
  BASEREF="${CITGATE_BASE:-HEAD}"; BASE_EXPLICIT="${CITGATE_BASE:+1}"; ALLT=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --base) [ $# -ge 2 ] || { echo "  [ERROR] --base needs a ref"; echo "CITATION_LINE_GATE=ERROR"; exit 41; }
              BASEREF="$2"; BASE_EXPLICIT=1; shift 2 ;;
      --all-targets) ALLT=1; shift ;;
      *) echo "  [ERROR] usage: $0 --all-files [--all-targets] [--base REF]"; echo "CITATION_LINE_GATE=ERROR"; exit 41 ;;
    esac
  done
  V=$(verdict_all "${CITGATE_ROOT:-$PWD}" "$BASEREF" "$BASE_EXPLICIT" "$ALL_PINS" "$ALLT" "$TARGET_PINS")
  print_all
  echo "CITATION_LINE_GATE=$V"
  case "$V" in PASS) exit 0 ;; ERROR) exit 41 ;; *) exit 40 ;; esac
fi

V=$(verdict_of "$DOC" "$SRC" "$BUDGET" "$KNOWN_KEYS")
sed -n 's/^COUNT /  [cite] /p;s/^NEW /  [NEW] /p;s/^VERDICT FAIL /  [FAIL] /p;s/^VERDICT-CONT /         /p;s/^VERDICT PASS /  [ok] /p;s/^ERROR /  [ERROR] /p' "$OUT"
echo "CITATION_LINE_GATE=$V"
case "$V" in PASS) exit 0 ;; ERROR) exit 41 ;; *) exit 40 ;; esac
