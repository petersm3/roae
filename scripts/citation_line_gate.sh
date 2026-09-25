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
# Pins: ALL_PINS (solve.c) plus TARGET_PINS below, keyed (citing file, target, anchor key, hash).
#
# ==================================================================================================
# REPIN-THEN-RESTALE AND CONTENT-HASHED PINS (the batch 7-10 pre-publication review S1/S3, and
# Q-793; Opus AF, 2026-09-25). MEASURED: batch 9 repinned a `tr12_repro.sh` citation, batch 10
# moved that awk 162 lines and edited the citing line, and with `--base 5c296837` the gate passed:
# leg A reads only BYTE-IDENTICAL citing lines, leg B read no `.tsv`, a common `.sh` word landed in
# the +-2 window by chance, and the 18 + 47 pins were keyed by NAME, so a pinned citation could
# point anywhere. Four changes, each red-tested in --selftest:
#   * LEG A2 (edited citing lines; see the block above `_bsrc` below). A number on a line the range
#     changed must be map(old), or carry the old cited text verbatim, or LAND by anchor, or be
#     vouched for by a content-hashed pin. Otherwise REPIN, a FAIL.
#   * LEG B reads `.tsv`, mining the note cell that carries the citation.
#   * RARITY RULE for `.sh` targets: an anchor on more than 3 lines of the script must be ON the
#     cited span; only a rare one keeps the +-2 slack.
#   * CONTENT-HASHED PINS (Q-793). Every pin row carries the 12-hex sha256 of its cited lines
#     (chash below). A stale citation is OPEN only when (file, target, key, hash) all match, so a pin
#     stops covering its citation the moment the cited content changes -- a shift, an edit of the
#     cited code, a repin -- and the gate reports "PINNED CONTENT CHANGED". Key `-` is an ATTESTED
#     pin: an unanchored citation a person checked by content. It vouches for that citation in leg
#     A2 and is exact like the others: when no citation of that file into that target has that
#     content any more, it FAILs until it is re-checked. CITGATE_PINROWS=1 prints the row, hash
#     included, for every stale or REPIN citation.
# A pin's hash depends only on the cited lines, never on the base, so the tables mean the same thing
# at pre-push (base = the remote tip) as in a local run against HEAD.

# THE --all-files PIN TABLE: <file> TAB <key> TAB <hash> TAB <reason>. One row per pinned citation;
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
# file	key	hash	reason
documentation/DEVELOPMENT.md	update_progress	ca1fe793f568	HISTORICAL by its own words: the callsite 'in the 2026-05-15 tree', a line of a named past tree, not of HEAD
documentation/QUERY_INVENTORY.md	--kc-profile	1a998633977c	QUOTES the retired wrong citation 16664ff (Q-540) to explain its re-anchoring; the live usage-block citation on the same row lands
documentation/QUERY_INVENTORY.md	--kc-profile	1a998633977c	the second number of that same quotation (16664 is a sidecar-write comment, which is the row's point)
documentation/QUERY_INVENTORY.md	(d, w)	29da842d5d58	LANDS: line 28002 opens the `"kernel"` object of raw cells (Opus UU repin, content-checked 2026-09-25); the placeholder m<a>_<b> is not source text and `kernel` is a plain word
documentation/SEARCH_SPACE_SIZE.md	E[W at a reached depth-32 leaf]	1aa64b021593	LANDS: line 8344 is `double se = sqrt(var / dn)`, the SE the sentence says is computed correctly; the sentence names no symbol of it
documentation/VERIFY.md	--help	35f11ed31bdd	SELF-ANNOTATED: the sentence itself says this number is stale and names f5_nuc's current line (dated 2026-09-21); keeping the retired number visible is an editorial choice
reports/TR12_QUERY_PROGRAM.md	(d, w)	29da842d5d58	LANDS: the same `"kernel"` emitter as QUERY_INVENTORY.md row V5 (line 28002)
reports/TR4_SIZE_OF_THE_SPACE.md	SOLVE_KNUTH_PIN_SLOTS	89f91885326d	LANDS: line 7899 is the knuth_pin_mask pair-index test; the env var that fills the mask is parsed elsewhere
scripts/doc_gates.sh	This read	71cca2890d80	HISTORICAL: names the header sentence at line 19 that carried a retracted phrase before ff804bb0; line 19 still holds that sentence, corrected, and the anchors on the line are that gate's own vocabulary
scripts/exec_lane.sh	--preflight	79a53af2bda3	LANDS: line 4112 is the disk-IOPS pre-check PASS fprintf; the comment paraphrases its words with '...', so nothing is verbatim
scripts/exec_lane_verdict_gate.sh	disk_iops_pre_check	9d2869f3b948	LANDS: line 4119 is the 'ERROR: projected fsync-wait' format string; the fixture below it is rendered output, not the format
scripts/tr12_repro.sh	$SOLVE	26292c76c925	LANDS: line 37077 is the in-memory-only refusal `if (fkc->ooc != NULL)` (Opus UU repin, content-checked); the row describes it in prose only
scripts/tr12_repro.sh	$SOLVE	b2335c01d0c4	LANDS: line 20692 is the `n > KC_MEM_MAX_PAIRS` out-of-core switch (Opus UU repin, content-checked); same row
solve.py	KC_SCAN	8641105daf4a	LANDS: line 29314 is `if (ok[i] == 0)`, the unconditional tail-failure count; gate_fails is bumped under `if (strict)` just outside the +-2 window
solve.py	%s\tcd=%d\t	10a6b42ea6c7	LANDS: line 38239 is the record-line emitter the comment cites; the cd= form it also names is the sibling at 38314
viz/report_figures.py	SOLVE_KNUTH_PIN_SLOTS	89f91885326d	LANDS: the same knuth_pin_mask test as TR4 (line 7899)
viz/report_figures.py	N_total	7c6ea7c736be	LANDS: line 41140 is `if (v >= 1 && v <= 31) knuth_pin_mask |= ...`; the env name is read 4 lines above, outside +-2
viz/viz_kc_grammar.md	--kc-raw	5ea7506691f6	LANDS: 28001-28010 is the `if (want_raw)` raw kernel-cell loop (Opus UU repin, content-checked); the flag itself is parsed elsewhere
# ATTESTED (key -): unanchored citations leg A2 met edited in the batch 1-10 range and a person checked by content
documentation/GT_LADDER_FORMAT.md	-	b766f36ff4eb	ATTESTED: line 21175 opens the 'independent forward brute force (the verification oracle)' block the sentence cites (content-checked 2026-09-25, Opus AF; cited from line 72)
documentation/GT_LADDER_FORMAT.md	-	3344cd723ce8	ATTESTED: line 21221 is `static void kc_brute(`, the brute-force list builder the sentence cites (content-checked 2026-09-25, Opus AF; cited from line 72)
solve.c	-	c68b08ebf7c7	ATTESTED: line 23342 is `if (k < 0 || k > fkc->n) {` in kc_g_check_layer_main (CX-89) (content-checked 2026-09-25, Opus AF; cited from line 37980)
solve.py	-	1e842b067951	ATTESTED: line 42948 is the sub-canonical gate `if (node_limit > 0 && node_limit < 1000000000000LL ...` (content-checked 2026-09-25, Opus AF; cited from line 6948)
solve.py	-	c41ad0b2c3ec	ATTESTED: line 23990 is the comment defining alts, the admissible oriented successors with g > 0 (content-checked 2026-09-25, Opus AF; cited from line 14167)
verify.py	-	0224b4f4cc0a	ATTESTED: line 6816 is `static inline int f5_nuc(int h)`, the encoding restated (content-checked 2026-09-25, Opus AF; cited from line 1977)
PINS
)
ALL_PINS="${CITGATE_ALL_PINS-$ALL_PINS_DEFAULT}"

# THE --all-targets PIN TABLE (Q-791): <citing file> TAB <target> TAB <key> TAB <hash> TAB <reason>, for stale
# citations into files OTHER than solve.c (solve.c's rows are the table above, reused as-is).
TARGET_PINS_DEFAULT=$(cat <<'PINS'
# file	target	key	hash	reason
documentation/CRITIQUE.md	documentation/CRITIQUE.md	a few hours	ece79aa85b24	LANDS: line 60 is the Gray-code C3 rate bound 'scoped to its sampler', the over-reach correction the note refers back to (self-reference)
documentation/CAMPAIGN_METHODOLOGY.md	documentation/HISTORY.md	origin/main	76d247e90143	LANDS: HISTORY.md line 4158 is the line carrying the 8-hex UUID prefix `3620ba16-…` the sentence describes
documentation/CAMPAIGN_METHODOLOGY.md	documentation/HISTORY.md	origin/main	0a6a430f95ad	LANDS: HISTORY.md line 1907 carries the `d63bb25c…` UUID token the sentence describes
documentation/CAMPAIGN_METHODOLOGY.md	documentation/HISTORY.md	9a968fa2	db73f707cca7	LANDS: HISTORY.md line 5146-5147 carry the old/new pre-merge shard totals (43,876,464,466) the cell names
documentation/CITATIONS.md	documentation/CITATIONS.md	6a3feaaa	c92bc6ec35bf	LANDS: line 401 is this section's preamble sentence (Suenaga ... initiated counting) that Q-127/Q-263 read; re-pinned by content 2026-09-25 (Q-791)
documentation/DEVELOPMENT.md	scripts/perf_bench.sh	--keep-vm	bd706672e0f3	LANDS: the four explicit `teardown` call sites in perf_bench.sh (re-measured 2026-09-25, Q-791: four, not three); the miner's anchors are the teardown function's words
documentation/DEVELOPMENT.md	scripts/perf_bench.sh	--keep-vm	33f0823c95ee	LANDS: the four explicit `teardown` call sites in perf_bench.sh (re-measured 2026-09-25, Q-791: four, not three); the miner's anchors are the teardown function's words
documentation/DEVELOPMENT.md	scripts/perf_bench.sh	--keep-vm	33f0823c95ee	LANDS: the four explicit `teardown` call sites in perf_bench.sh (re-measured 2026-09-25, Q-791: four, not three); the miner's anchors are the teardown function's words
documentation/DEVELOPMENT.md	scripts/perf_bench.sh	--keep-vm	fa1236b01ff5	LANDS: the four explicit `teardown` call sites in perf_bench.sh (re-measured 2026-09-25, Q-791: four, not three); the miner's anchors are the teardown function's words
documentation/QUERY_INVENTORY.md	solve.py	PENDING	ae4bda73379b	LANDS: solve.py line 13673 is `def atlas_emit_xa`, the XA consumer the ruling describes (re-pinned from line 12062ff, which pointed there at a19682b2)
documentation/QUERY_INVENTORY.md	solve.py	extrema	57492d7cc487	LANDS: the Q6 'per-distance-class mass, not per-(state,choice)' comment in solve.py (re-pinned 2026-09-25, Q-791); the anchors mined are the row's other words
documentation/QUERY_INVENTORY.md	solve.py	extrema	7bef2b9d6798	LANDS: the Q6 'per-distance-class mass, not per-(state,choice)' comment in solve.py (re-pinned 2026-09-25, Q-791); the anchors mined are the row's other words
documentation/QUERY_INVENTORY.md	viz/viz_kc_grammar.md	(d, w)	fa49f1697728	LANDS: viz_kc_grammar.md line 61-62 is where the new-pair category is stated to be undefined in TR-12 section 2 (re-pinned from line 44, Q-791)
documentation/QUERY_INVENTORY.md	scripts/tr12_repro.sh	TR12_Q7	8cc56d7454e8	LANDS: tr12_repro.sh line 3626 is `agg(){`, the helper definition the sentence names; the row's anchors are the two agg call sites (line 3640/line 3645, which land)
documentation/SOLUTIONS_FORMAT.md	runs/20260419_100T_d3_d128westus3/README.md	_10T_d3_d128westus3	5883f38a672d	LANDS: the run README's line 10 is 'Solver commit at enumeration launch'; the only mined anchor is a directory-name fragment
documentation/SOLVE_C_CLI.md	solve.py	--books-verify	b91ac445daea	LANDS: solve.py line 10496-10499 is the Goldenberg attribution block (re-pinned from line 9682-9685, Q-791)
documentation/SOLVE_C_CLI.md	documentation/CITATIONS.md	--books-verify	2b094b79c0be	LANDS: CITATIONS.md line 2646 is the goldenberg1975 ledger anchor (re-pinned from line 1855, Q-791)
documentation/SOLVE_PY_CLI.md	solve.py	--tr8-dof-pool-draws	0ced75f2076d	LANDS: solve.py line 1093-1096 writes results.json / RESULTS.md, the results writer the sentence means (re-pinned from line 1023, Q-791)
documentation/SOLVE_PY_CLI.md	solve.py	"timing-probe"	62c3f79731e3	LANDS: the pool-seed use (line 901) and results writer (line 1093-1096) named in the re-pin note itself (Q-791)
documentation/SOLVE_PY_CLI.md	solve.py	"timing-probe"	0ced75f2076d	LANDS: the pool-seed use (line 901) and results writer (line 1093-1096) named in the re-pin note itself (Q-791)
documentation/SOLVE_PY_CLI.md	documentation/DISTRIBUTIONAL_ANALYSIS.md	--joint-density	1a97db3cd038	LANDS: DISTRIBUTIONAL_ANALYSIS.md line 217 opens the de-circularized two-dimension re-run the cell points to
documentation/VERIFY.md	documentation/CITATIONS.md	exact count	b1fcd3e28e64	LANDS: CITATIONS.md line 416 and line 1501 carry 'validated estimates for C1-C5' beside the exact C1-C2-C4-C5 layer counts (re-pinned from line 346/line 964, Q-791)
documentation/VERIFY.md	documentation/CITATIONS.md	exact count	9a036f732bdb	LANDS: CITATIONS.md line 416 and line 1501 carry 'validated estimates for C1-C5' beside the exact C1-C2-C4-C5 layer counts (re-pinned from line 346/line 964, Q-791)
documentation/VERIFY.md	documentation/DESCRIPTION_LENGTH.md	|C1–C7|	5071a89ad75a	LANDS: DESCRIPTION_LENGTH.md line 77 is '|C1∩C4∩C5| = |C1∩C2∩C4∩C5| exactly. The C3 conditional remains sampled by design.'
reports/TR12_QUERY_PROGRAM.md	viz/viz_kc_grammar.md	(d, w)	fa49f1697728	LANDS: the same viz_kc_grammar.md line 61-62 category-undefined passage as QUERY_INVENTORY.md row V5 (Q-791)
reports/TR9_PRICING_THE_CONSTRAINTS.md	documentation/DESCRIPTION_LENGTH.md	 relaxation** of	924ab4666b2e	LANDS: DESCRIPTION_LENGTH.md line 54 is the '+ C2 (no-5)' table row, the sibling cell (re-pinned from line 36, which it was at 6ffab778; Q-791)
reports/TR9_PRICING_THE_CONSTRAINTS.md	documentation/DESCRIPTION_LENGTH.md	 relaxation** of	4370fc8a5cfd	LANDS: DESCRIPTION_LENGTH.md line 205-207 is the 2026-07-10 C2 refinement paragraph, the second sibling (re-pinned from line 127-129, Q-791)
scripts/doc_gates.sh	documentation/CORRECTIONS.md	quoted	a624447579f8	LANDS: CORRECTIONS.md line 4146-4147 is the ledger's quotation of the retired 'maximum by construction' sentence (re-pinned from line 4121, where it was at b69f13f1; Q-791)
scripts/doc_gates.sh	reports/TR6_PARITY_SKELETON.md	at the time of the SAT work (×11,364),	818de1e7b4fb	LANDS: TR6:132-133 carry the qualifier, hard-wrapped across the two lines, so the verbatim fragment is on neither
scripts/doc_gates.sh	reports/TR4_SIZE_OF_THE_SPACE.md	sharpens further when S(6..8) land	047717c1306d	LANDS: TR4:361 is the P34 wording ('sharpened by the 2026-07-05 S(6)-S(8) measurement'); the anchor is the retired wording the red test restores
scripts/doc_gates.sh	documentation/CLAIM_TO_ARTIFACT.md	canonical	f37fef14dbf6	LANDS: CLAIM_TO_ARTIFACT.md line 45 is the n=9 26,112 row (row 14; re-pinned from line 41, Q-791); 'canonical' is the word the defect removed
scripts/doc_gates.sh	documentation/PROJECT_OVERVIEW.md	_10T_d3_fresh	19b739cabf35	LANDS: PROJECT_OVERVIEW.md line 102 attributes 21,794,755 / 152,468,987 to d3 10T; the anchor is the log path, named elsewhere
scripts/doc_gates.sh	documentation/LARGE_SCALE_CAMPAIGNS.md	sort + dedup	07cecd264fdd	LANDS: LARGE_SCALE_CAMPAIGNS.md line 1026 is 'There is no S at which you need code that does not exist' (re-pinned from line 995, Q-791)
scripts/exec_lane.sh	documentation/SOLVE_C_CLI.md	./solve	f7fa3e543185	LANDS: SOLVE_C_CLI.md line 3545 quotes the pre-correction build line (re-pinned from line 2061, Q-791)
scripts/exec_lane.sh	documentation/CORRECTIONS.md	--follow	025e532dcecf	LANDS: CORRECTIONS.md line 3189 carries the bare `git log -S` fragment (re-pinned from line 3164, Q-791)
scripts/exec_lane_verdict_gate.sh	documentation/BRANCHES_EXPLAINED.md	--branch	a4a6e06c28ce	LANDS: BRANCHES_EXPLAINED.md line 382 is '**All-branch enumeration** (`solve 0 64`)' (re-pinned from line 383, Q-791)
scripts/pre_commit_generated_gate.sh	roae.py	--seed	9cd17968a666	LANDS: roae.py line 23 is `_global_seed = None`, i.e. seeds nothing by default (re-pinned from line 22, Q-791)
scripts/tr12_repro.sh	documentation/GT_LADDER_FORMAT.md	--kc-t-check	cb9ac715fe11	LANDS: GT_LADDER_FORMAT.md line 297 is 'integrity checks: they constrain the FILES, not the shared'; this text is a row_skip REASON emitted into the goldens, so it is pinned, not reworded
scripts/tr12_repro.sh	documentation/GT_LADDER_FORMAT.md	--kc-t-check	cb9ac715fe11	LANDS: the same GT_LADDER_FORMAT.md line 297 sentence, in the sibling row_skip reason (goldens text)
scripts/tr12_repro.sh	scripts/tr12_repro.sh	by_class	d0a7ac7a7790	LANDS: line 2978 is the F-5 D11 fix in row c_v1 (self-reference, re-pinned from line 2260, Q-791)
scripts/tr12_repro_gate.sh	scripts/tr12_repro_gate.sh	, which is pre_push_gate.sh's variable and is unset here --	00d251fa549e	LANDS: line 225/line 229 are the q2_witness leg's `./scripts/...` repo-relative paths, the idiom named (self-reference, re-pinned from line 306/line 318, Q-791)
scripts/tr12_repro_gate.sh	scripts/tr12_repro_gate.sh	, which is pre_push_gate.sh's variable and is unset here --	b923394391cb	LANDS: line 225/line 229 are the q2_witness leg's `./scripts/...` repo-relative paths, the idiom named (self-reference, re-pinned from line 306/line 318, Q-791)
solve.py	tests.py	--kc-tdir	85890e4eebc6	LANDS: tests.py line 6211 is a minimal `"gates": {"fails": 0}` fixture (re-pinned from line 5655, Q-791)
solve.py	documentation/SOLVE_C_CLI.md	KC_SCAN	11173c521dec	LANDS: SOLVE_C_CLI.md line 2249-2250 is the corrected paragraph quoting the claim that this loader closed it (re-pinned from line 2238, Q-791)
solve.py	viz/viz_kc_field.md	layers	77a7b41c3bc3	LANDS: viz_kc_field.md line 34 is 'Index the ordering by its 32 pair-slots', the published convention the comment quotes
tests.py	sat.py	--keep	ac0e6d6eba88	LANDS: sat.py line 1854 is the `_run_tool(["d4", ...])` call (re-pinned from line 1823, Q-791); 'd4' is too short to mine
tests.py	solve.py	--rules	2e018c376311	LANDS: solve.py line 1649-1657 is print_rules' docstring withdrawal plus the retired-banner comment (re-pinned from line 1581, Q-791)
documentation/DEVELOPMENT.md	scripts/tr12_repro.sh	--kc-o3-rank	a3c7ef14609e	LANDS (rarity rule): line 2629 is the n>=31 rank3 awk the row names; `--kc-o3-rank` occurs on 11 lines of tr12_repro.sh and sits on the comment above the awk, not on it
documentation/DEVELOPMENT.md	scripts/tr12_repro.sh	--kc-o3-rank	941b26ee7499	LANDS (rarity rule): line 653 is the q1c rank3 awk, the first sibling the row names (re-pinned from line 642 by content, 2026-09-25: 642 was one line of CX-93's shift behind); same common anchor
documentation/RETRACTED_PHRASES.tsv	documentation/DEVELOPMENT.md	Constraint set	a1e7684b2f3b	LANDS: DEVELOPMENT.md line 2459-2461 is the Xugua sentence the note describes (review S3 re-pin by content, 2026-09-25); the mined anchor is the METHODS.md section name the note also quotes
documentation/RETRACTED_PHRASES.tsv	solve.py	--rules	be32b4e7bc0b	HISTORICAL by its own words: solve.py line 1581 'at the 2026-09-02 HEAD', the run-time banner title; print_rules is at solve.py line 1646 today
documentation/RETRACTED_PHRASES.tsv	solve.py	--rules	dcdccd4d30ac	HISTORICAL by its own words: the print_rules() comment GATE 6 fired on at the row's 2026-09-02 build
documentation/RETRACTED_PHRASES.tsv	solve.py	--rules	e849e24fe9f9	HISTORICAL by its own words: the 'B2 MEASURED' negation sites at the row's 2026-09-02 build
documentation/RETRACTED_PHRASES.tsv	documentation/SOLVE_PY_CLI.md	--rules	3f83ae6f9546	HISTORICAL by its own words: 'B2 MEASURED' at the row's 2026-09-02 build; the negation now sits at SOLVE_PY_CLI.md line 105
# ATTESTED (key -): unanchored citations leg A2 met edited in the batch 1-10 range and a person checked by content
documentation/DOC_GATE_EMITTED_SURFACE_OPEN.tsv	scripts/tr12_repro_gate.sh	-	1e178531ce02	ATTESTED: line 503 is the `printf 'TR12_A=PASS\n...'` fixture literal the row names (review S1 re-pin) (content-checked 2026-09-25, Opus AF; cited from line 50)
documentation/ROAE_PY_CLI.md	roae.py	-	5dd6051f8a32	ATTESTED: line 5077 is `gate_ok = abs(p_le_648 - 0.04789) <= 0.005`, the constant the sentence names (content-checked 2026-09-25, Opus AF; cited from line 428 and line 436; reason re-pinned from line 4994, Fable HH N2)
documentation/SOLVE_C_CLI.md	documentation/DEVELOPMENT.md	-	fdde236ba43a	ATTESTED: DEVELOPMENT.md line 1579 is the 'Caveat — cross-host reproducibility' paragraph that bounds the tested toolchain class (content-checked 2026-09-25, Opus AF; cited from line 208)
documentation/VERIFY.md	documentation/CLAIM_TO_ARTIFACT.md	-	8a71d7b9b18c	ATTESTED: CLAIM_TO_ARTIFACT.md line 34 is row 3, |C1∩C2∩C4∩C5| EXACT, the qualification the sentence means (content-checked 2026-09-25, Opus AF; cited from line 1054)
scripts/doc_gates.sh	reports/TR2_THE_RULES_CONFLICT.md	-	75d1d558ef44	ATTESTED: TR2 line 587 is the bold label 'Stop-flag resolution (v1.12, 2026-07-13)' the comment quotes (content-checked 2026-09-25, Opus AF; cited from line 1775)
scripts/doc_gates.sh	documentation/DESCRIPTION_LENGTH.md	-	01dd010f3e03	ATTESTED: DESCRIPTION_LENGTH.md line 74 carries the decimal ×23.325025987… the fixture names (content-checked 2026-09-25, Opus AF; cited from line 12402)
scripts/doc_gates.sh	documentation/CITATIONS.md	-	91ee7e608492	ATTESTED: CITATIONS.md line 1976-1977 is the gender/position-parity bullet with the 'at the time of the SAT work' qualifier (content-checked 2026-09-25, Opus AF; cited from line 15807)
scripts/doc_gates.sh	documentation/DEPLOYMENT.md	-	5738628c0c1a	ATTESTED: DEPLOYMENT.md line 166 is the d3 100T merge bullet, 'external merge streams in chunks' (an affirmation) (content-checked 2026-09-25, Opus AF; cited from line 19835)
scripts/exec_lane.sh	documentation/SOLUTIONS_FORMAT.md	-	1a3f74ef552c	ATTESTED: SOLUTIONS_FORMAT.md line 437 is `env | grep -c '^SOLVE_DEPTH='` returning 0 (content-checked 2026-09-25, Opus AF; cited from line 770)
scripts/q7ranks_parse_gate.sh	scripts/tr12_repro.sh	-	a3c7ef14609e	ATTESTED: line 2629 is the n>=31 rank3 awk of a2_q7_ranks (review S1 re-pin) (content-checked 2026-09-25, Opus AF; cited from line 95)
scripts/q7ranks_parse_gate.sh	scripts/tr12_repro.sh	-	a3c7ef14609e	ATTESTED: line 2629 is the n>=31 rank3 awk of a2_q7_ranks (review S1 re-pin) (content-checked 2026-09-25, Opus AF; cited from line 103)
scripts/q7ranks_parse_gate.sh	scripts/tr12_repro.sh	-	941b26ee7499	ATTESTED: line 653 is the q1c rank3 awk, the first sibling (review S1 re-pin) (content-checked 2026-09-25, Opus AF; cited from line 103)
scripts/q7ranks_parse_gate.sh	scripts/tr12_repro.sh	-	1dbdb132ab0c	ATTESTED: line 2700 is the a2_q3 `--kc-o3-rank ... | awk` rank3 parse, the second sibling (review S1 re-pin) (content-checked 2026-09-25, Opus AF; cited from line 103)
scripts/tr12_repro_gate.sh	scripts/tr12_repro.sh	-	37b8c4bff44f	ATTESTED: line 1202 is `row_begin a0_q4b` (review S1 re-pin) (content-checked 2026-09-25, Opus AF; cited from line 148)
solve.c	solve.py	-	a2eec7945003	ATTESTED: solve.py line 7111 is `"SOLVE_HASH_LOG2": "16",  # keep RAM use modest on tiny VMs`, quoted (content-checked 2026-09-25, Opus AF; cited from line 39724)
solve.c	documentation/SOLVE_C_CLI.md	-	13caa29fe0ed	ATTESTED: SOLVE_C_CLI.md line 518 is `set -a; eval "$(./solve --canonical-config 100T)"; set +a` (content-checked 2026-09-25, Opus AF; cited from line 41952)
solve.c	verify.py	-	e7a7c32b284b	ATTESTED: verify.py line 7127-7128 print KW_PRESENT then KW_REQUIRED, the pair mirrored (content-checked 2026-09-25, Opus AF; cited from line 43415)
solve.c	documentation/SOLVE_C_CLI.md	-	fc6e90f7a78a	ATTESTED: SOLVE_C_CLI.md line 791 is 'King Wen presence is reported, not enforced' (content-checked 2026-09-25, Opus AF; cited from line 43649)
solve.c	verify.py	-	e7a7c32b284b	ATTESTED: verify.py line 7127-7128 print KW_PRESENT then KW_REQUIRED, the pair mirrored (content-checked 2026-09-25, Opus AF; cited from line 43850)
PINS
)
TARGET_PINS="${CITGATE_TARGET_PINS-$TARGET_PINS_DEFAULT}"

_run_all() { # $1 root  $2 base ref  $3 base-explicit (1|"")  $4 pins  $5 all-targets (1|"")  $6 target pins
  ROOT="$1" BASE="$2" BASE_EXPLICIT="$3" PINS="$4" ALLT="${5:-}" TPINS="${6:-}" python3 - <<'PYEOF'
import difflib, hashlib, os, re, subprocess, sys
from collections import Counter, defaultdict
root, base, base_explicit, pins_raw = (os.environ[k] for k in ("ROOT", "BASE", "BASE_EXPLICIT", "PINS"))
allt, tpins_raw = os.environ["ALLT"] == "1", os.environ["TPINS"]
sys.stdout.reconfigure(line_buffering=True)   # PINROW audit lines go to stderr: keep the two in order
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
def cites(line, citer, prev=(), quiet=False):
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
            if os.environ.get("CITGATE_PINROWS") == "1" and not quiet:   # audit trail: which file each bare :N was read as
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
# A TREE is accepted as well as a commit (Q-793 lane, 2026-09-25): assembly checks each batch against the previous
# batch's `git write-tree`, which is a tree with no commit around it. `git diff` and `git show
# <tree>:<path>` both take one.
rc, _ = git(["rev-parse", "--verify", "-q", base + "^{tree}"])
based = rc == 0
if rc != 0:
    if base_explicit:
        print("ERROR base ref %r does not resolve to a commit or a tree" % base); sys.exit(0)
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
        legA_note = ("no tracked file is" if allt else "solve.c is not") + \
                    " changed against %s -- nothing moved, leg A vacuous" % base
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

# ---- LEG B scope and matching (the batch 7-10 review, S1/S3 class, 2026-09-25) --------------------
# * `.tsv` is in scope. A registry row's NOTE cell carries citations (RETRACTED_PHRASES.tsv,
#   DOC_GATE_*_OPEN.tsv) and no leg read them: DOC_GATE_EMITTED_SURFACE_OPEN.tsv:50 sat on a `}` for
#   a whole batch. Anchors are mined from the ONE cell that carries the citation -- the other
#   columns (a retracted phrase, a key, an allow-list) are different claims from the note's.
# * RARITY RULE for `.sh` targets. A script repeats its own vocabulary (`awk`, `ARTDIR`, `row_begin`,
#   a variable) on hundreds of lines, so under the +-2 window some mined word lands BY CHANCE; the
#   review found two stale `tr12_repro.sh` citations green that way. An anchor that occurs on more
#   than RARE (3) lines of a .sh target now counts only when it is on the cited span itself; a rare
#   one keeps the +-2 slack. MEASURED (see DEVELOPMENT.md, CITATION_LINE_GATE): the chance-landing
#   rate of deliberately shifted .sh citations falls, and no unshifted citation turned stale.
#   CITGATE_SH_TIGHT=0 restores the old rule; it exists to reproduce that measurement.
# * CITGATE_PROBE_SHIFT=k adds k to every leg-B citation before judging it. It is the POSITIVE
#   CONTROL for the leg: with k != 0 almost every checkable citation must go stale, and the ones
#   that do not are the leg's chance landings. Never set it in a gate run.
LEGB = re.compile(r'\.(?:md|py|sh|tsv)$')
SH_TIGHT = os.environ.get("CITGATE_SH_TIGHT", "1")
RARE = 3
PROBE = int(os.environ.get("CITGATE_PROBE_SHIFT", "0") or 0)
_occ = {}
def occ(t, c):
    if (t, c) not in _occ:
        _occ[(t, c)] = sum(1 for l in tsrc(t)[0] if c in l)
    return _occ[(t, c)]

def tsv_cell(line, t):
    for cell in line.split("\t"):
        if t in cell:
            return cell
    return line

def chash(src, lo, hi):
    """Q-793: the content hash a pin carries -- 12 hex of sha256 over the cited lines lo..hi of the
    target (trailing blanks stripped). A pinned citation whose target CONTENT changes, for any
    reason (a shift, an edit of the cited code, a repin to another line), no longer matches its pin."""
    body = "\n".join(x.rstrip() for x in src[lo - 1:hi]) if 1 <= lo and hi <= len(src) else "<out-of-range>"
    return hashlib.sha256(body.encode("utf-8", "replace")).hexdigest()[:12]

def judge_b(tg, lo, hi, ctx, heading, ismd):
    """Leg B on one citation -> (state, key, anchors); state is lands | stale | unchk."""
    src, srctext = tsrc(tg)
    cands = candidates(ctx, tg) | (candidates(heading, tg) if ismd else set())
    cands = {c for c in cands if c in srctext}
    if not cands:
        return "unchk", None, []
    lo, hi = lo + PROBE, hi + PROBE
    win, core = src[max(0, lo - 3):max(0, hi + 2)], src[max(0, lo - 1):max(0, hi)]
    hit = False
    for c in cands:
        if any(c in l for l in win):
            if (SH_TIGHT != "0" and tg.endswith(".sh") and occ(tg, c) > RARE
                    and not any(c in l for l in core)):
                continue                 # a common word two lines off is chance, not a landing
            hit = True; break
    if lo < 1 or hi > len(src) or not hit:
        return "stale", sorted(cands)[0], sorted(cands)
    return "lands", sorted(cands)[0], sorted(cands)

# ---- LEG A2: an EDITED citing line (the batch 7-10 review, S1, 2026-09-25) -----------------------
# Leg A reads only a citing line the change left byte-identical. A citation that is repinned and
# then re-staled INSIDE ONE push range (batch 9 repinned a tr12_repro.sh citation to line 2467,
# batch 10 moved the code 162 lines, the citing line was edited in between) is invisible to it. Leg A2 takes
# every citation on a line the range DID change, finds that line's counterpart at BASE (the most
# similar line of its own diff hunk that carries a citation, similarity >= 0.5), and pairs each new
# citation with the base's citations of the SAME target. The new number is accepted when it is
#   (1) FOLLOWED   -- map(old) through the target's base->head line map, i.e. it moved with the code;
#   (2) MOVED-WITH -- the cited base lines, verbatim (trailing blanks aside, >= 8 characters), are the
#                     new cited lines: the code was moved by a rewrite the map cannot see through;
#   (3) ANCHORED   -- leg B checks it and it LANDS (rarity rule included), or it is leg-B stale and
#                     matched by a content-hashed pin, which is a reviewed attestation of that content.
# Anything else is a REPIN failure: the number changed to something neither the line map nor the
# target's content explains. A citation with no base counterpart (a new line, a new target) is
# FRESH and left to leg B. The leg needs a base; like leg A it is vacuous on a clean tree at HEAD.
_bsrc = {}
def base_src(t):
    if t not in _bsrc:
        rc, bt = git(["show", "%s:%s" % (base, t)])
        _bsrc[t] = bt.split("\n") if rc == 0 else None
    return _bsrc[t]

_chunks = {}
def hunks_of(p):
    if p in thunks:
        return thunks[p]
    if p not in _chunks:
        rc, d = git(["diff", "-U0", "--no-color", "--no-ext-diff", "--no-renames", base, "--", p])
        _chunks[p] = [tuple(int(x) if x != '' else 1 for x in hh) for hh in
                      re.findall(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@', d, re.M)] if rc == 0 else []
    return _chunks[p]

CITEISH = re.compile(r'\.[A-Za-z]{1,5}`?\)?:\d|[(`\s]:\d')
def counterpart(p, li, line):
    """The base line number this edited line replaced, or None (a new line)."""
    bl = base_src(p)
    if bl is None:
        return None
    for os_, ol, ns, nl in hunks_of(p):
        if nl and ns <= li < ns + nl:
            best, bj = 0.0, None
            for j in range(os_ - 1, os_ - 1 + ol if ol else os_ - 1):
                o = bl[j] if 0 <= j < len(bl) else ""
                if not CITEISH.search(o):
                    continue
                sm = difflib.SequenceMatcher(None, line, o, autojunk=False)
                if sm.real_quick_ratio() < 0.5 or sm.quick_ratio() < 0.5:
                    continue
                r = sm.ratio()
                if r > best:
                    best, bj = r, j
            return bj + 1 if bj is not None and best >= 0.5 else None
    return None

def moved_with(bs, a, b, hs, lo, hi):
    if b - a != hi - lo or a < 1 or lo < 1 or b > len(bs) or hi > len(hs):
        return False
    x = "\n".join(s.strip() for s in bs[a - 1:b])
    return len(re.sub(r'\s', '', x)) >= 8 and x == "\n".join(s.strip() for s in hs[lo - 1:hi])

shift, inhunk, stale, cited = [], [], [], set()
pend, a2 = [], Counter()
bstate, sh_ck, sh_st, att_seen = {}, Counter(), Counter(), Counter()
totA = totB = checked = 0
for p in files:
    try:
        lines = open(p, encoding="utf-8", errors="replace").read().split("\n")
    except OSError:
        continue
    base_lines = None
    if based and p in changed:
        rc, bt = git(["show", "%s:%s" % (base, p)])
        base_lines = Counter(bt.split("\n")) if rc == 0 else Counter()
    heading, isb, ismd, istsv = "", bool(LEGB.search(p)), p.endswith(".md"), p.endswith(".tsv")
    for li, line in enumerate(lines, 1):
        if ismd and line.startswith("#"):
            heading = line
        prev = []
        j = li - 2
        while j >= 0 and len(prev) < 15 and lines[j].strip():
            prev.append(lines[j]); j -= 1
        cs_line = cites(line, p, prev)
        if not cs_line:
            continue
        # LEG A (a citing line this change left byte-identical)
        if base_lines is None or base_lines[line] > 0:
            for tg, lo, hi, t in (cs_line if hunks else ()):
                totA += 1
                ml, mh = lmap(lo, tg), lmap(hi, tg)
                tt = t if tg == "solve.c" else "%s [%s]" % (t, tg)
                if ml is None or mh is None:
                    inhunk.append("%s:%d %s" % (p, li, tt))
                elif ml != lo or mh != hi:
                    shift.append("%s:%d %s -> map %s" % (p, li, tt, ml if lo == hi else "%d-%d" % (ml, mh)))
        # LEG A2 (a citing line this change edited)
        else:
            oli = counterpart(p, li, line)
            olds = []
            if oli is not None:
                bl = base_src(p)
                oprev, j = [], oli - 2
                while j >= 0 and len(oprev) < 15 and bl[j].strip():
                    oprev.append(bl[j]); j -= 1
                ex0, im0 = excluded.copy(), implied_n.copy()
                olds = cites(bl[oli - 1], p, oprev, quiet=True)
                excluded.clear(); excluded.update(ex0); implied_n.clear(); implied_n.update(im0)
            for tg, lo, hi, t in cs_line:
                prior = [(a, b) for tg0, a, b, _ in olds if tg0 == tg]
                if not prior:
                    a2["fresh"] += 1; continue
                a2["edited"] += 1
                if any(lmap(a, tg) == lo and lmap(b, tg) == hi for a, b in prior):
                    a2["followed"] += 1; continue
                bs = base_src(tg)
                if bs is not None and any(moved_with(bs, a, b, tsrc(tg)[0], lo, hi) for a, b in prior):
                    a2["moved-with"] += 1; continue
                pend.append((p, li, t, tg, lo, hi, prior))
        # LEG B
        for tg, lo, hi, t in cs_line:
            h = chash(tsrc(tg)[0], lo, hi)
            att_seen[(p, tg, h)] += 1    # every citation, so an attested pin means the same in both modes
            if not isb:                  # outside leg B's scope: only an ATTESTED pin can vouch for it
                bstate[(p, li, tg, lo, hi)] = ("unchk", None, h)
                continue
            totB += 1
            cited.add(tg)
            if istsv and not line.lstrip().startswith("#"):
                ctx = tsv_cell(line, t)
            else:
                ctx = context(lines, li, ismd)
            st, key, cands = judge_b(tg, lo, hi, ctx, heading, ismd)
            bstate[(p, li, tg, lo, hi)] = (st, key, h)
            if st == "unchk":
                continue
            checked += 1
            sh_ck[tg.endswith(".sh")] += 1
            if st == "stale":
                stale.append((p, tg, li, t, key, cands, h))
                sh_st[tg.endswith(".sh")] += 1

# Pins are keyed (citing file, target, anchor key, target content hash) -- Q-793. The solve.c table
# has 4 columns (file TAB key TAB hash TAB reason; its target is solve.c); the --all-targets table
# has 5 (file TAB target TAB key TAB hash TAB reason). The hash is chash() of the cited span.
pins, pinned_keys = Counter(), Counter()
for raw, ncol in ((pins_raw, 4), (tpins_raw if allt else "", 5)):
    for r in raw.split("\n"):
        if not r.strip() or r.lstrip().startswith("#"):
            continue
        f = r.split("\t")
        if len(f) < ncol or not f[ncol - 1].strip() or not re.fullmatch(r'[0-9a-f]{12}', f[ncol - 2]):
            print("ERROR malformed pin row (need %s TAB <12-hex content hash> TAB reason): %r"
                  % ("file TAB key" if ncol == 4 else "file TAB target TAB key", r)); sys.exit(0)
        k = (f[0], "solve.c", f[1], f[2]) if ncol == 4 else (f[0], f[1], f[2], f[3])
        pins[k] += 1
        pinned_keys[k[:3]] += 1

if totB == 0 or checked == 0:
    print("ERROR leg B found %d citation(s), %d checkable -- measured nothing" % (totB, checked)); sys.exit(0)

seen = Counter((p, tg, k, h) for p, tg, _, _, k, _, h in stale)
repin = []
for p, li, t, tg, lo, hi, prior in pend:
    st, k, h = bstate.get((p, li, tg, lo, hi), ("unchk", None, None))
    if st == "lands":
        a2["anchored"] += 1; continue
    if st == "stale" and pins[(p, tg, k, h)] >= seen[(p, tg, k, h)]:
        a2["pinned"] += 1; continue
    if pins[(p, tg, "-", h)] > 0:
        a2["attested"] += 1; continue
    tt = t if tg == "solve.c" else "%s [%s]" % (t, tg)
    mp = ", ".join((str(a) if a == b else "%d-%d" % (a, b)) + " -> map " +
                   ("inhunk" if lmap(a, tg) is None or lmap(b, tg) is None else
                    str(lmap(a, tg)) if a == b else "%d-%d" % (lmap(a, tg), lmap(b, tg))) for a, b in prior)
    repin.append("%s:%d %s was %s; leg B: %s" % (p, li, tt, mp,
                 {"unchk": "no anchor", "stale": "stale"}.get(st, st)))
    if os.environ.get("CITGATE_PINROWS") == "1":
        sys.stderr.write("PINROW\t%s\t%s\t%s\t%s\t%s:%d %s\n" % (p, tg, "-" if st == "unchk" else k, h, p, li, t))

print(("COUNT all-targets cited-targets=%d implied-self=%d implied-context=%d\n"
       % (len(cited), implied_n[True], implied_n[False]) if allt else "")
      + "COUNT files=%d legB total=%d checked=%d stale=%d uncheckable=%d pinned=%d"
      % (len(files), totB, checked, len(stale), totB - checked, sum(pins.values())))
print("COUNT legB .sh-targets checked=%d stale=%d; other targets checked=%d stale=%d%s"
      % (sh_ck[True], sh_st[True], sh_ck[False], sh_st[False],
         "" if SH_TIGHT != "0" else " (rarity rule OFF)") + (" PROBE-SHIFT=%+d" % PROBE if PROBE else ""))
print("COUNT excluded " + (" ".join("%s=%d" % kv for kv in sorted(excluded.items())) or "none"))
if legA_note:
    print("COUNT legA " + legA_note)
else:
    print("COUNT legA base=%s files-moved=%d hunks=%d unmoved-citations=%d shifted=%d inhunk=%d"
          % (base, len(thunks), sum(len(v) for v in thunks.values()), totA, len(shift), len(inhunk)))
if based and changed:
    print("COUNT legA2 edited=%d fresh=%d followed=%d moved-with=%d anchored=%d pinned=%d attested=%d repin=%d"
          % (a2["edited"], a2["fresh"], a2["followed"], a2["moved-with"], a2["anchored"], a2["pinned"],
             a2["attested"], len(repin)))
for s in shift:
    print("SHIFT " + s)
for s in inhunk:
    print("INHUNK " + s)
for s in repin:
    print("REPIN " + s)
hashes_of = defaultdict(list)
for k in pins:
    hashes_of[k[:3]].append(k[3])
for p, tg, li, t, k, cs, h in stale:
    ok = seen[(p, tg, k, h)] <= pins[(p, tg, k, h)]
    moved = "" if ok or not hashes_of[(p, tg, k)] else \
        " -- PINNED CONTENT CHANGED (pin %s, target now %s)" % ("/".join(sorted(set(hashes_of[(p, tg, k)]))), h)
    print("%s %s:%d %s%s names %s%s" % ("OPEN" if ok else "NEW", p, li, t,
                                        "" if tg == "solve.c" else " [%s]" % tg, ",".join(cs[:4]), moved))
    if os.environ.get("CITGATE_PINROWS") == "1":      # a pin-table row, key verbatim (keys may hold commas)
        sys.stderr.write("PINROW\t%s\t%s\t%s\t%s\t%s:%d %s\n" % (p, tg, k, h, p, li, t))
bad = []
if shift:
    bad.append("leg A: %d citation(s) left behind by a %s shift" % (len(shift), "target-file" if allt else "solve.c"))
if repin:
    bad.append("leg A2: %d edited citation(s) now name a line that neither the line map nor the "
               "target's content explains" % len(repin))
new = sorted(k for k in seen if seen[k] > pins[k])
gone = sorted(k for k in pins if k[2] != "-" and seen[k] < pins[k])
gone_att = sorted(k for k in pins if k[2] == "-" and att_seen[(k[0], k[1], k[3])] < pins[k])
if new:
    bad.append("leg B: stale citation(s) beyond the pin: " + ", ".join("%s->%s[%s]#%s" % k for k in new))
if gone:
    bad.append("leg B: pinned stale citation(s) no longer stale at the pinned content -- TIGHTEN or "
               "RE-HASH the pin: " + ", ".join("%s->%s[%s]#%s" % k for k in gone))
if gone_att:
    bad.append("leg A2: attested pin(s) match no unanchored citation at that content -- the citation "
               "moved or its target changed; RE-CHECK and re-hash, or drop: "
               + ", ".join("%s->%s#%s" % (k[0], k[1], k[3]) for k in gone_att))
if bad:
    for b in bad:
        print("VERDICT FAIL " + b)
else:
    print("VERDICT PASS leg A %s; leg A2 %d repin; leg B %d stale, all pinned exactly"
          % ("vacuous" if legA_note else "0 shifted", len(repin), len(stale)))
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
  sed -n 's/^COUNT /  [cite] /p;s/^SHIFT /  [SHIFT] /p;s/^INHUNK /  [inhunk] /p;s/^REPIN /  [REPIN] /p;s/^NEW /  [NEW] /p;s/^OPEN /  [open] /p;s/^VERDICT FAIL /  [FAIL] /p;s/^VERDICT PASS /  [ok] /p;s/^ERROR /  [ERROR] /p;/^PINROW\t/p' "$OUT"
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

  # The content hash a pin carries (Q-793), computed the way the gate's chash() computes it.
  hsh() { python3 -c 'import hashlib, sys
src = open(sys.argv[1], encoding="utf-8", errors="replace").read().split("\n"); lo, hi = int(sys.argv[2]), int(sys.argv[3])
body = "\n".join(x.rstrip() for x in src[lo - 1:hi]) if 1 <= lo and hi <= len(src) else "<out-of-range>"
print(hashlib.sha256(body.encode("utf-8", "replace")).hexdigest()[:12])' "$1" "$2" "${3:-$2}"; }

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
  PIN1=$(printf 'doc.md\talpha_beta_gamma\t%s\tselftest pin' "$(hsh "$R/solve.c" 8)")
  i=$(verdict_all "$R" HEAD "" "$PIN1")
  printf "$L1$L2" 8 10 >"$R/doc.md"        # repaired, but the pin was left behind -> FAIL
  j=$(verdict_all "$R" HEAD "" "$PIN1")
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
  PIN2=$(printf 'doc2.md\thelper.sh\twidget_total\t%s\tselftest pin' "$(hsh "$R2/helper.sh" 9)")
  m6=$(verdict_all "$R2" HEAD "" "" 1 "$PIN2")
  printf "$D2" 1 5 7 >"$R2/doc2.md"                # repaired, pin left behind -> FAIL
  m7=$(verdict_all "$R2" HEAD "" "" 1 "$PIN2")
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
  [ "$rc" = 0 ] && echo "  [ok] red-test --all-targets: M0=PASS M1=PASS(plain blind) M2=FAIL(shift incl. self-ref) M3=PASS M4=PASS(@sha) M5=FAIL M6=PASS M7=FAIL"

  # LEG A2, .tsv, CONTENT-HASHED PINS and the .sh RARITY RULE (review S1/S3 + Q-793, 2026-09-25),
  # on a third throwaway repo. helper.sh (base, 12 lines): `widget_total() {` 3, `}` 5,
  # `rare_marker_fn() {` 6, and `$ARTDIR` on lines 7 and 9-12 (5 lines: a COMMON word).
  # doc3.md line 1 names nothing, so leg B cannot check it -- only leg A2 can; line 3 is anchored
  # so leg B has something to measure. reg.tsv's NOTE cell cites the same function.
  R3="$W/r3"; mkdir -p "$R3"
  G3() { git -C "$R3" -c user.name=selftest -c user.email=selftest@invalid "$@" >/dev/null 2>&1; }
  G3 init -q
  printf 'static int kc_widget_count;\n' >"$R3/solve.c"
  mk_h3() { { printf "$1"; printf '#!/bin/sh\n# helper\nwidget_total() {\n  echo "$SOLVE_TOTAL_WIDGETS"\n}\nrare_marker_fn() {\n  echo "$ARTDIR"\n}\n'
              printf 'echo "$ARTDIR" %s\n' one two three four; } >"$R3/helper.sh"; }
  D3='The function body ends at helper.sh:%s.\n\nThe `rare_marker_fn` helper is at helper.sh:%s.\n'
  T3='# registry\nrow1\tvalue\tthe `rare_marker_fn` helper is defined at helper.sh:%s\n'
  mk_h3 ''; printf "$D3" 5 6 >"$R3/doc3.md"; printf "$T3" 6 >"$R3/reg.tsv"
  G3 add -A; G3 commit -q -m base
  n0=$(verdict_all "$R3" HEAD "" "" 1 "")                       # clean -> PASS
  # One range: +2 lines at the top of helper.sh, and doc3.md line 1 is EDITED (reworded) while its
  # number stays 5 -- the repin-then-restale shape. Line 3 and the .tsv follow the code (+2).
  mk_h3 '# ins 1\n# ins 2\n'; printf "$T3" 8 >"$R3/reg.tsv"
  D3E='The closing brace of the function is at helper.sh:%s.\n\nThe `rare_marker_fn` helper is at helper.sh:%s.\n'
  printf "$D3E" 5 8 >"$R3/doc3.md"
  n1=$(verdict_all "$R3" HEAD "" "" 1 ""); n1o=$(cat "$OUT")    # REPIN -> FAIL, leg A and B silent
  printf "$D3E" 7 8 >"$R3/doc3.md"
  n2=$(verdict_all "$R3" HEAD "" "" 1 "")                       # followed the code -> PASS
  printf "$D3E" 6 8 >"$R3/doc3.md"
  n3=$(verdict_all "$R3" HEAD "" "" 1 "")                       # neither map nor content -> FAIL
  ATT3=$(printf 'doc3.md\thelper.sh\t-\t%s\tselftest attested' "$(hsh "$R3/helper.sh" 6)")
  n4=$(verdict_all "$R3" HEAD "" "" 1 "$ATT3")                  # a person attested it -> PASS
  G3 add -A; G3 commit -q -m attested                           # published: no range can see it now
  n4b=$(verdict_all "$R3" HEAD "" "" 1 "$ATT3")                 # the attestation still holds -> PASS
  sed -i '6s/.*/  echo "$SOLVE_TOTAL_WIDGETS" edited/' "$R3/helper.sh"
  n5=$(verdict_all "$R3" HEAD "" "" 1 "$ATT3"); n5o=$(cat "$OUT")   # attested content changed -> FAIL
  # A stale .tsv note, committed (so no leg A/A2 range can see it): only leg B's .tsv read can.
  mk_h3 '# ins 1\n# ins 2\n'; printf "$D3E" 7 8 >"$R3/doc3.md"; printf "$T3" 14 >"$R3/reg.tsv"
  G3 add -A; G3 commit -q -m tsv-stale
  n6=$(verdict_all "$R3" HEAD "" "" 1 ""); n6o=$(cat "$OUT")    # stale .tsv -> FAIL
  PIN3=$(printf 'reg.tsv\thelper.sh\trare_marker_fn\t%s\tselftest pin' "$(hsh "$R3/helper.sh" 14)")
  n7=$(verdict_all "$R3" HEAD "" "" 1 "$PIN3")                  # pinned at its content -> PASS
  sed -i '14s/four/FOUR/' "$R3/helper.sh"                      # the cited line changes; nothing moves
  n8=$(verdict_all "$R3" HEAD "" "" 1 "$PIN3"); n8o=$(cat "$OUT")   # Q-793: the pin no longer covers it -> FAIL
  # The .sh RARITY RULE. After the +2, `$ARTDIR` is on lines 9 and 11-14; line 10 is `}`. A
  # citation of line 10 for `ARTDIR` lands under the +-2 window by chance only.
  mk_h3 '# ins 1\n# ins 2\n'; printf "$T3" 8 >"$R3/reg.tsv"
  printf "$D3E"'\nThe `ARTDIR` echo is at helper.sh:%s.\n' 7 8 10 >"$R3/doc3.md"; G3 add -A; G3 commit -q -m rar
  n9=$(verdict_all "$R3" HEAD "" "" 1 "")                       # common word, 1 line off -> FAIL
  n10=$(CITGATE_SH_TIGHT=0 verdict_all "$R3" HEAD "" "" 1 "")   # the pre-rule window -> PASS (the blind spot)
  printf "$D3E"'\nThe `ARTDIR` echo is at helper.sh:%s.\n' 7 8 9 >"$R3/doc3.md"; G3 add -A; G3 commit -q -m rar2
  n11=$(verdict_all "$R3" HEAD "" "" 1 "")                      # on the cited line -> PASS
  [ "$n0" = PASS ] || { echo "  [gate] leg N0 (clean) gave $n0, want PASS"; rc=1; }
  [ "$n1" = FAIL ] || { echo "  [gate] leg N1 (edited citing line, number left behind) gave $n1, want FAIL"; rc=1; }
  grep -qxF "$(printf 'REPIN doc3.md:%d helper.sh:%d [helper.sh] was 5 -> map 7; leg B: no anchor' 1 5)" <<<"$n1o" \
                   || { echo "  [gate] leg N1 did not print the REPIN line"; rc=1; }
  grep -q '^SHIFT \|^NEW ' <<<"$n1o" && { echo "  [gate] leg N1: leg A or B fired too, so N1 does not isolate leg A2"; rc=1; }
  [ "$n2" = PASS ] || { echo "  [gate] leg N2 (edited line, number followed the code) gave $n2, want PASS"; rc=1; }
  [ "$n3" = FAIL ] || { echo "  [gate] leg N3 (edited line, unexplained number) gave $n3, want FAIL"; rc=1; }
  [ "$n4" = PASS ] || { echo "  [gate] leg N4 (the same, attested by content hash) gave $n4, want PASS"; rc=1; }
  [ "$n4b" = PASS ] || { echo "  [gate] leg N4b (attested, committed, unchanged) gave $n4b, want PASS"; rc=1; }
  [ "$n5" = FAIL ] || { echo "  [gate] leg N5 (attested citation's target content changed) gave $n5, want FAIL"; rc=1; }
  grep -q '^VERDICT FAIL leg A2: attested pin' <<<"$n5o" || { echo "  [gate] leg N5 did not fail on the attested pin"; rc=1; }
  grep -q '^REPIN \|^SHIFT \|^NEW ' <<<"$n5o" && { echo "  [gate] leg N5: another leg fired, so N5 does not isolate the attested pin"; rc=1; }
  [ "$n6" = FAIL ] || { echo "  [gate] leg N6 (stale .tsv note) gave $n6, want FAIL"; rc=1; }
  grep -qF "$(printf 'NEW reg.tsv:%d helper.sh:%d [helper.sh] names rare_marker_fn' 2 14)" <<<"$n6o" \
                   || { echo "  [gate] leg N6 did not report the reg.tsv row"; rc=1; }
  [ "$n7" = PASS ] || { echo "  [gate] leg N7 (the .tsv defect pinned with its content hash) gave $n7, want PASS"; rc=1; }
  [ "$n8" = FAIL ] || { echo "  [gate] leg N8 (pinned citation's target content changed) gave $n8, want FAIL"; rc=1; }
  grep -q 'PINNED CONTENT CHANGED' <<<"$n8o" || { echo "  [gate] leg N8 did not say PINNED CONTENT CHANGED"; rc=1; }
  [ "$n9" = FAIL ] || { echo "  [gate] leg N9 (.sh common anchor one line off) gave $n9, want FAIL"; rc=1; }
  [ "$n10" = PASS ] || { echo "  [gate] leg N10 (same, rarity rule off) gave $n10, want PASS"; rc=1; }
  [ "$n11" = PASS ] || { echo "  [gate] leg N11 (.sh common anchor on the cited line) gave $n11, want PASS"; rc=1; }
  if [ "$rc" = 0 ]; then echo "  [ok] red-test A2/tsv/hash/rarity: N0=PASS N1=FAIL(repin-restale, A2 alone) N2=PASS N3=FAIL N4=PASS(attested) N4b=PASS N5=FAIL(attested content changed, alone) N6=FAIL(.tsv) N7=PASS N8=FAIL(pinned content changed) N9=FAIL N10=PASS(rule off) N11=PASS"
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
