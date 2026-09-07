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
# subcommand at `solve.c:32614`; takes **none**." under a `### --kc-...` heading. Mining the
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
BUDGET="${CITGATE_BUDGET:-57}"
KNOWN_KEYS="${CITGATE_KEYS:---analyze,--cpu-features,--double-regression-test,--emit-shard-manifest,--estimate-knuth,--kde-score-stream,--merge,--merge-layers,--preflight,--print-config,--prove-cascade,--prove-self-comp,--prove-shift,--regression-test,--selftest,--selftest-resume,--show,--sub-branch,--threshold,--validate,--verify,--verify-rule2,--verify-shard-manifest,SOLVE_CKPT_INTERVAL,SOLVE_COMPRESS,SOLVE_DEPTH,SOLVE_KNUTH_FIBER_PERM,SOLVE_KNUTH_SCORE_REG,SOLVE_MEMORY_FLUSH_COUNT,SOLVE_SUB_BRANCH_PARALLELISM,SOLVE_THREADS,UNLISTED,auto_emit_shard_manifest_default,in_bytes}"

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

if [ "${1:-}" = "--selftest" ]; then
  # RED-TEST IN BOTH DIRECTIONS. The isolating case is ONE DIGIT of ONE citation: legs A and B
  # share byte-identical source and doc except that B's citation says 4 where A's says 3. If the
  # gate cannot tell those apart it is checking nothing, and a wrong line number is exactly the
  # defect it exists to catch.
  W=$(mktemp -d); trap 'rm -f "$OUT"; rm -rf "$W"' EXIT
  printf 'int a;\nint b;\nstatic int sub_ckpt_interval_sec = 60;\nint c;\n' >"$W/s.c"
  printf 'Row: `SOLVE_CKPT_INTERVAL` is `sub_ckpt_interval_sec` (solve.c:3).\n' >"$W/a.md"
  printf 'Row: `SOLVE_CKPT_INTERVAL` is `sub_ckpt_interval_sec` (solve.c:4).\n' >"$W/b.md"
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
  if [ "$rc" = 0 ]; then echo "  [ok] red-test: A=PASS B=FAIL C=ERROR D=PASS (A vs B differ by one digit)"
                         echo "CITATION_LINE_GATE=PASS"; exit 0
  else echo "CITATION_LINE_GATE=FAIL"; exit 40; fi
fi

V=$(verdict_of "$DOC" "$SRC" "$BUDGET" "$KNOWN_KEYS")
sed -n 's/^COUNT /  [cite] /p;s/^NEW /  [NEW] /p;s/^VERDICT FAIL /  [FAIL] /p;s/^VERDICT-CONT /         /p;s/^VERDICT PASS /  [ok] /p;s/^ERROR /  [ERROR] /p' "$OUT"
echo "CITATION_LINE_GATE=$V"
case "$V" in PASS) exit 0 ;; ERROR) exit 41 ;; *) exit 40 ;; esac
