#!/usr/bin/env bash
# tr12_output_paths_gate.sh — Q-684. Every TR-12 output path the public docs name must be one
# that exists: a `reports/tr12/` name must be tracked, and an `<artifact-root>/` name must be a
# file scripts/tr12_repro.sh writes. (The tables were a top-level `tr12/` directory until
# 2026-09-29, CX-233; see LEG L for how that older prefix is read.)
#
# WHY. TR-12 named its outputs in two forms and nothing checked either one.
#   * `tr12/<file>`. On 2026-09-22 the report named six files under a `tr12/` directory that
#     had never been tracked. doc_gates.sh GATE 21 checks backticked paths only under a CURRENT
#     top-level tracked directory, computed at run time, so while `tr12/` did not exist its
#     names were invisible to it. That is the gap this leg closes: it checks the prefix whether
#     or not the directory exists (`reports/tr12/` since 2026-09-29, LEG T; the old one, LEG L).
#   * `<artifact-root>/<file>`. The query sections used this placeholder four times and never
#     defined it, and three of the four names matched nothing the battery writes:
#     `q1_rank_kw.txt` (the script writes q1_rank.json), a `gallery/` directory (it writes
#     q8_super.tsv, q8_c15.tsv and q8_chi2.txt) and `q3_profile_kw.tsv` at the root (the
#     consumer writes it under consumer/). The viz docs and SOLVE_C_CLI.md repeated the Q3
#     name. No gate reads a placeholder path, so no gate could see any of this.
#
# WHAT IS CHECKED. Every inline code span (single backticks, outside fenced blocks) in every
# tracked *.md file, EXCEPT documentation/CORRECTIONS.md and documentation/HISTORY.md (append-
# only: they must be able to quote a withdrawn name) and the body of any `## Revision history`
# section (append-only for the same reason).
#   LEG T  a span that IS a path beginning `reports/tr12/` (no spaces, no `<`, no `*`, no `{`)
#          must be a tracked file, or, when it ends in `/`, a directory holding at least one
#          tracked file.
#   LEG L  (CX-233, 2026-09-29) a span beginning `tr12/`, the location of the same files before
#          they moved under reports/. In a live doc it FAILS: it points at a directory that no
#          longer exists. It is read as HISTORICAL, and resolved through the one-row legacy map
#          `tr12/` -> `reports/tr12/`, in exactly two places: any file under reports/evidence/
#          (banked receipts and their READMEs, some covered by SHA256SUMS, which record where the
#          files were when the run happened), and a (file, span) row on HISTORICAL_SPANS (a live
#          doc quoting its own former wording). A mapped span must still resolve, so a
#          historical name for a file that was never tracked still fails; a HISTORICAL_SPANS row
#          that matches no span FAILS as dead. CORRECTIONS.md, HISTORY.md and `## Revision
#          history` sections are skipped whole, as before.
#   LEG A  a span that IS a path beginning `<artifact-root>/NAME` must name a path the battery
#          writes: `$ARTDIR/NAME` appears literally in scripts/tr12_repro.sh, or NAME ends in `/`
#          and some literal `$ARTDIR/NAME...` path lies under it. A name under `consumer/` is
#          also accepted when the script writes `$ARTDIR/consumer` and the basename is a quoted
#          string literal in solve.py (the atlas consumer's own emitters).
#   NO-PRODUCER list  a name the docs publish as a SPECIFICATION with no producer. Each row
#          says why. A row FAILS when the script starts writing that name (the exception has
#          outlived its reason) and when no scanned doc names it any more (a dead row).
#
# SCOPE LIMITS, so a PASS is not read as more than it is. It does not check bare basenames
# (`q10_orbit_census.tsv` with no directory), paths inside fenced code blocks, or names under
# any other placeholder root. It cannot tell whether a produced file holds what the prose says.
#
# 🔴 IT IS NOT SATISFIED BY ITS OWN EMPTINESS. No scanned span at all, an unreadable battery
# script, or a battery script with no `$ARTDIR/` literal is an ERROR, never a pass.
#
# COST: one `git ls-files`, one read of each tracked *.md, one read of tr12_repro.sh and
# solve.py. About 1 s. No build, no network.
#
# Usage:
#   scripts/tr12_output_paths_gate.sh              # the repository this script sits in
#   scripts/tr12_output_paths_gate.sh --root DIR   # another git checkout
#   scripts/tr12_output_paths_gate.sh --selftest   # prove each leg discriminates
#
# Verdict tokens (grep -qx), each a WHOLE line:
#   TR12_OUTPUT_PATHS=PASS|FAIL|ERROR       exit 0 | 1 | 2
#   TR12_OUTPUT_PATHS_CHECKED=<n>           spans checked (printed before the verdict)
#   TR12_OUTPUT_PATHS_ERROR=<cause>         ERROR only
#   TR12_OUTPUT_PATHS_SELFTEST=PASS|FAIL    --selftest only (exit 0 | 1)
set -uo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
root="$here"
mode=run
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="${2:-}"; shift 2 || { echo "TR12_OUTPUT_PATHS_ERROR=bad-args"; echo "TR12_OUTPUT_PATHS=ERROR"; exit 2; } ;;
    --selftest) mode=selftest; shift ;;
    *) echo "TR12_OUTPUT_PATHS_ERROR=bad-args"; echo "TR12_OUTPUT_PATHS=ERROR"; exit 2 ;;
  esac
done

# Q-965: headings and fences are read through the shared markdown normaliser of doc_gates.sh. It is
# sourced from THIS script's checkout ($here), not from --root, so a planted --selftest repository
# needs no copy of it; a missing normaliser is an ERROR, never a silent raw-line scan.
. "$here/scripts/doc_gates.d/md_normalise.sh" 2>/dev/null && declare -F _md_norm_prelude >/dev/null \
  || { echo "TR12_OUTPUT_PATHS_ERROR=normaliser-unreadable"; echo "TR12_OUTPUT_PATHS=ERROR"; exit 2; }
# Q-966: and the shared word/token matcher, the same way, for the comment-stripped battery below.
. "$here/scripts/doc_gates.d/word_match.sh" 2>/dev/null && declare -F _wm_prelude >/dev/null \
  || { echo "TR12_OUTPUT_PATHS_ERROR=matcher-unreadable"; echo "TR12_OUTPUT_PATHS=ERROR"; exit 2; }

run_gate() {  # $1 = checkout root
  { _md_norm_prelude; _wm_prelude; cat <<'PY'
import os, re, subprocess, sys

root = sys.argv[1]

def verdict(v, rc, cause=None):
    if cause:
        print("TR12_OUTPUT_PATHS_ERROR=%s" % cause)
    print("TR12_OUTPUT_PATHS=%s" % v)
    sys.exit(rc)

# (name under <artifact-root>/, why it is published with no producer)
NO_PRODUCER = [
    ("q10_coset_census.tsv",
     "TR-12 Q10(b): the coset census is specified and has no producer; --kc-coset-census does "
     "not exist and TR12_Q10B stays PENDING (TR-12 section 11)"),
    ("spectrum/v3_spectrum.tsv",
     "viz/viz_kc_spectrum.md: the per-order spectrum path the renderer reads first; nothing "
     "writes it, the O3 route is unbuilt, and the renderer falls back to the committed flat "
     "reports/tr12/v3_spectrum.tsv"),
]

# LEG L. The directory's pre-2026-09-29 prefix and where it lives now (CX-233).
LEGACY = ("tr12/", "reports/tr12/")
# Files whose every `tr12/` span is historical: banked evidence records where the files were.
HISTORICAL_PREFIXES = ("reports/evidence/",)
# (file, span, why): a live doc that quotes its own former wording, so the old prefix is the
# quote, not a pointer. Each row must still match a span (a dead row FAILS).
HISTORICAL_SPANS = [
    ("reports/TR12_QUERY_PROGRAM.md", "tr12/",
     "section 0's inline correction of 2026-09-24 quotes the sentence it corrected, "
     "\"no `tr12/` directory is tracked in this repository\""),
    ("documentation/DEVELOPMENT.md", "tr12/",
     "the TR12_OUTPUT_PATHS token row narrates Q-684 of 2026-09-25, when TR-12 named files "
     "under a `tr12/` directory that was not yet tracked"),
]

try:
    tracked = subprocess.run(["git", "-C", root, "ls-files", "-z"], capture_output=True,
                             check=True).stdout.decode("utf-8", "replace").split("\0")
except Exception:
    verdict("ERROR", 2, "not-a-git-checkout")
tracked = [t for t in tracked if t]
tset = set(tracked)

try:
    battery = open(os.path.join(root, "scripts", "tr12_repro.sh"), encoding="utf-8").read()
except OSError:
    verdict("ERROR", 2, "battery-unreadable")
# Q-966 (A02#17): a COMMENT is not a producer. `# cp "$RAW" "$ARTDIR/x.tsv"` in the battery made x.tsv
# "written" while nothing writes it; the battery is read with its shell comments blanked.
written = set(re.findall(r"\$ARTDIR/([A-Za-z0-9_./-]*[A-Za-z0-9_])", wm_strip_comments(battery, "sh")))
if not written:
    verdict("ERROR", 2, "battery-has-no-ARTDIR-literal")
has_consumer = "$ARTDIR/consumer" in wm_strip_comments(battery, "sh")
try:
    solvepy = open(os.path.join(root, "solve.py"), encoding="utf-8").read()
except OSError:
    solvepy = ""
try:
    solvepy = wm_strip_comments(solvepy, "py")      # Q-966: a quoted name in a comment is not a consumer
except Exception:
    verdict("ERROR", 2, "solve.py-untokenizable")

def produced(name):
    """Does the battery write <artifact-root>/name ?"""
    if name.endswith("/"):
        return any(w.startswith(name) for w in written)
    if name in written:
        return True
    if name.startswith("consumer/") and has_consumer:
        base = name[len("consumer/"):]
        if base and ('"%s"' % base in solvepy or "'%s'" % base in solvepy):
            return True
    return False

SKIP = {"documentation/CORRECTIONS.md", "documentation/HISTORY.md"}
PATHISH = re.compile(r"^[A-Za-z0-9_./-]+$")
span_re = re.compile(r"`([^`\n]+)`")
checked = 0
fails = []
named_noprod = set()
used_hist = set()
hist_spans = {(hf, ht) for hf, ht, _ in HISTORICAL_SPANS}

def tracked_path(tok):
    return (tok in tset) if not tok.endswith("/") else any(t.startswith(tok) for t in tset)

for f in sorted(t for t in tracked if t.endswith(".md") and t not in SKIP):
    try:
        lines, kinds, blks, _unc = md_parse(open(os.path.join(root, f), encoding="utf-8").read())
    except (OSError, UnicodeDecodeError):
        continue
    # Q-965 (A02#14, A02#15): fences are matched by opener (a ~~~ line inside a ``` block is content,
    # not a toggle), a heading line is SCANNED like any other line (a broken path on a "## See ..."
    # heading passed), and a "## Revision history" section ends at the next heading of level 1 OR 2
    # (a "# Current usage" after it stayed exempt to end of file). Any heading form counts.
    hlev = {b["start"]: (b["level"], b["text"]) for b in blks if b["kind"] == "heading"}
    in_rev = False
    for i, line in enumerate(lines, 1):
        if kinds[i - 1] in ("code", "fence"):
            continue
        if i in hlev and hlev[i][0] <= 2:
            in_rev = hlev[i][0] == 2 and hlev[i][1].strip().lower() == "revision history"
        if in_rev:
            continue
        for m in span_re.finditer(line):
            tok = m.group(1).strip()
            if tok.startswith(LEGACY[1]):
                if not PATHISH.match(tok):
                    continue
                checked += 1
                if not tracked_path(tok):
                    fails.append("%s:%d `%s` is not tracked" % (f, i, tok))
            elif tok.startswith(LEGACY[0]):
                if not PATHISH.match(tok):
                    continue
                checked += 1
                hist = f.startswith(HISTORICAL_PREFIXES) or (f, tok) in hist_spans
                if not hist:
                    fails.append("%s:%d `%s` names the pre-2026-09-29 location; the tables are "
                                 "under `%s` now (CX-233)" % (f, i, tok, LEGACY[1]))
                    continue
                if (f, tok) in hist_spans:
                    used_hist.add((f, tok))
                mapped = LEGACY[1] + tok[len(LEGACY[0]):]
                if not tracked_path(mapped):
                    fails.append("%s:%d `%s` (historical; now `%s`) is not tracked" % (f, i, tok, mapped))
            elif tok.startswith("<artifact-root>/"):
                name = tok[len("<artifact-root>/"):]
                if not name or not PATHISH.match(name):
                    continue
                checked += 1
                if any(name == n for n, _ in NO_PRODUCER):
                    named_noprod.add(name)
                    continue
                if not produced(name):
                    fails.append("%s:%d `%s` is not a path scripts/tr12_repro.sh writes" % (f, i, tok))

for hf, ht, _ in HISTORICAL_SPANS:
    if (hf, ht) not in used_hist:
        fails.append("HISTORICAL_SPANS row (%s, `%s`) matches no span; remove the dead row" % (hf, ht))

for n, why in NO_PRODUCER:
    if produced(n):
        fails.append("NO-PRODUCER row `%s` now HAS a producer in scripts/tr12_repro.sh; remove the "
                     "row (its reason was: %s)" % (n, why))
    elif n not in named_noprod:
        fails.append("NO-PRODUCER row `%s` is named by no scanned doc; remove the dead row" % n)

print("TR12_OUTPUT_PATHS_CHECKED=%d" % checked)
if checked == 0:
    verdict("ERROR", 2, "no-spans-scanned")
for x in fails:
    print("  [FAIL] " + x)
if fails:
    verdict("FAIL", 1)
print("  [ok] %d span(s): every reports/tr12/ name is tracked, every historical tr12/ name maps to a "
      "tracked file, and every <artifact-root>/ name is written by scripts/tr12_repro.sh or on the "
      "no-producer list (%d row(s))" % (checked, len(NO_PRODUCER)))
verdict("PASS", 0)
PY
  } | python3 - "$1"
}

if [ "$mode" = run ]; then
  command -v python3 >/dev/null 2>&1 || { echo "TR12_OUTPUT_PATHS_ERROR=python3-absent"; echo "TR12_OUTPUT_PATHS=ERROR"; exit 2; }
  run_gate "$root"
  exit $?
fi

# ---- --selftest: a planted repository per case; each must get its expected verdict ----------
tmp=$(mktemp -d "${TMPDIR:-/tmp}/tr12_outpaths_st.XXXXXX") || { echo "TR12_OUTPUT_PATHS_SELFTEST=FAIL"; exit 1; }
trap 'rm -rf "$tmp"' EXIT
bad=0
plant() {  # $1 = dir; writes a minimal clean repository
  mkdir -p "$1/scripts" "$1/reports/tr12/scan" "$1/reports/evidence/tr12" "$1/viz"
  cat > "$1/scripts/tr12_repro.sh" <<'SH'
ARTDIR="$OUTDIR/artifacts"
cp "$RAW" "$ARTDIR/q1_rank.json"
cp "$RAW" "$ARTDIR/q8_super.tsv"
python3 solve.py --atlas-out "$ARTDIR/consumer"
SH
  printf 'NAME = "q3_profile_kw.tsv"\n' > "$1/solve.py"
  printf 'x\n' > "$1/reports/tr12/q3_profile_kw.tsv"; printf 'x\n' > "$1/reports/tr12/scan/v1_field.tsv"
  printf 'banked: the committed `tr12/q3_profile_kw.tsv` at run time\n' > "$1/reports/evidence/tr12/README.md"
  printf 'this read "no `tr12/` directory is tracked"\n' > "$1/reports/TR12_QUERY_PROGRAM.md"
  mkdir -p "$1/documentation"; printf 'Q-684: files under a `tr12/` directory\n' > "$1/documentation/DEVELOPMENT.md"
  cat > "$1/reports/TR.md" <<'MD'
# TR
Output `<artifact-root>/q1_rank.json`, `<artifact-root>/consumer/q3_profile_kw.tsv`,
committed `reports/tr12/q3_profile_kw.tsv`, scan under `reports/tr12/scan/`, template `tr12/<file>`.
Specified only: `<artifact-root>/q10_coset_census.tsv`.
```bash
cp x tr12/not_tracked_in_a_fence.txt   # `tr12/fenced.tsv`
```
## Revision history
| v1 | old | this once read `<artifact-root>/q1_rank_kw.txt` and `tr12/q9_negatives.md` |
MD
  printf 'spec `<artifact-root>/spectrum/v3_spectrum.tsv`\n' > "$1/viz/spec.md"
  ( cd "$1" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm t ) >/dev/null 2>&1
}
expect() {  # $1 = case label, $2 = expected verdict, $3 = dir
  local out v
  out=$(run_gate "$3" 2>&1)
  v=$(printf '%s\n' "$out" | grep -x 'TR12_OUTPUT_PATHS=[A-Z]*' | tail -1)
  if [ "$v" = "TR12_OUTPUT_PATHS=$2" ]; then echo "  [ok] $1 -> $2"
  else echo "  [FAIL] $1: expected $2, got '${v:-<none>}'"; printf '%s\n' "$out" | sed 's/^/         /'; bad=1; fi
}
commit() { ( cd "$1" && git add -A && git -c user.email=t@t -c user.name=t commit -qm m ) >/dev/null 2>&1; }

d="$tmp/c0"; plant "$d"; expect "clean planted repository" PASS "$d"
d="$tmp/c1"; plant "$d"; printf 'Q1 `<artifact-root>/q1_rank_kw.txt`\n' >> "$d/viz/spec.md"; commit "$d"
expect "an <artifact-root>/ name the battery does not write (the old Q1 text)" FAIL "$d"
d="$tmp/c2"; plant "$d"; printf 'Q8 `<artifact-root>/gallery/`\n' >> "$d/viz/spec.md"; commit "$d"
expect "an <artifact-root>/ directory the battery does not write (the old Q8 text)" FAIL "$d"
d="$tmp/c3"; plant "$d"; printf 'Q3 `<artifact-root>/q3_profile_kw.tsv`\n' >> "$d/viz/spec.md"; commit "$d"
expect "a consumer file placed at the artifact root (the old Q3 text)" FAIL "$d"
d="$tmp/c4"; plant "$d"; printf 'see `reports/tr12/q10_coset_census.tsv`\n' >> "$d/viz/spec.md"; commit "$d"
expect "an untracked reports/tr12/ file (the 2026-09-22 shape)" FAIL "$d"
d="$tmp/c5"; plant "$d"; ( cd "$d" && git rm -rq reports/tr12 ) >/dev/null 2>&1; commit "$d"
expect "reports/tr12/ names with no reports/tr12/ directory at all" FAIL "$d"
d="$tmp/c11"; plant "$d"; printf 'see `tr12/q3_profile_kw.tsv`\n' >> "$d/viz/spec.md"; commit "$d"
expect "a live doc naming the pre-2026-09-29 tr12/ location (LEG L)" FAIL "$d"
d="$tmp/c12"; plant "$d"; printf 'and `tr12/never_tracked.tsv`\n' >> "$d/reports/evidence/tr12/README.md"; commit "$d"
expect "a historical tr12/ name in evidence that maps to no tracked file (LEG L)" FAIL "$d"
d="$tmp/c13"; plant "$d"; printf 'unquoted\n' > "$d/reports/TR12_QUERY_PROGRAM.md"; commit "$d"
expect "a HISTORICAL_SPANS row that matches no span (LEG L dead row)" FAIL "$d"
d="$tmp/c6"; plant "$d"; printf 'cp x "$ARTDIR/q10_coset_census.tsv"\n' >> "$d/scripts/tr12_repro.sh"; commit "$d"
expect "a NO-PRODUCER name that gained a producer" FAIL "$d"
d="$tmp/c7"; plant "$d"; sed -i 's/Specified only.*//' "$d/reports/TR.md"; commit "$d"
expect "a NO-PRODUCER row no doc names any more" FAIL "$d"
d="$tmp/c10"; plant "$d"; printf '```\nQ1 `<artifact-root>/q1_rank_kw.txt`\n```\n' >> "$d/viz/spec.md"; commit "$d"
expect "a bad name inside a fenced block (not a span; out of scope)" PASS "$d"
d="$tmp/c8"; plant "$d"; sed -i 's/ARTDIR/OUTDIR/g' "$d/scripts/tr12_repro.sh"; commit "$d"
expect "a battery script with no \$ARTDIR/ literal" ERROR "$d"
d="$tmp/c9"; plant "$d"; ( cd "$d" && git rm -q reports/TR.md viz/spec.md reports/TR12_QUERY_PROGRAM.md reports/evidence/tr12/README.md documentation/DEVELOPMENT.md ) >/dev/null 2>&1; commit "$d"
expect "no span to check" ERROR "$d"
if [ "$bad" -eq 0 ]; then echo "TR12_OUTPUT_PATHS_SELFTEST=PASS"; exit 0; fi
echo "TR12_OUTPUT_PATHS_SELFTEST=FAIL"; exit 1
