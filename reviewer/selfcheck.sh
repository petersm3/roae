#!/usr/bin/env bash
# reviewer/selfcheck.sh — the self-check of the ROAE reviewer package (reviewer/README.md).
#
# WHAT IT DOES. It reads the numbered steps out of reviewer/README.md ("## The steps"), runs each
# one exactly as written, and checks each step's printed output against the `expect:` lines under
# it. It curates no command of its own: if the page and this script disagree, the page wins and the
# check fails.
#
# ISOLATION. The steps run in a fresh scratch directory that holds COPIES of exactly the package's
# input files (the list PKG_FILES below, printed by --files) and nothing else. Outputs a reader has
# already made by hand (solve, verify, out13/, kc13/, run13.log) are never copied in, so a step
# cannot resume or reuse them, and nothing a step writes, even through a file of the same name,
# can reach the package directory. (Before 2026-10-02 the scratch directory linked EVERY entry of
# the package directory, outputs included; Codex PKG-V1 finding 1 showed step 4 resuming a reader's
# finished out13/ and overwriting their run13.log.)
#
# PASS RULE. A step passes only when its command exits 0 AND every one of its `expect:` lines
# matches. Each command runs as `bash -o pipefail -c '<command>'`, so a failing program before a
# `| tee` fails the step, and with every inherited SOLVE_* variable removed. An expectation matches
# a WHOLE output line (leading and trailing blanks ignored). The one exception is an expectation
# that ends in " …": the output line must then BEGIN with the text before " …", followed by a blank
# or the end of the line (for lines that end in a timing). An expectation of the form KEY=VALUE
# also fails if any other line sets the same KEY to a different value, or if the expected line
# appears more than once. (Before 2026-10-02 other
# expectations were substring matches, so "KC COUNT n=13 = 20633956070400", ten times the right
# count, passed; Codex PKG-V1 finding 2.)
# A step that runs past SELFCHECK_STEP_TIMEOUT seconds (default 1800; exit 124) is [TIMEOUT], and
# one killed by a signal (exit 129..192) is [CRASH]: it did not finish, so whatever it printed is
# not evidence, and the run ends REVIEWER_PACKAGE=ERROR, never PASS or FAIL (batch 39).
# The page also states how many steps it has ("There are **N steps**"). The count of numbered steps
# must equal N, and the steps must be numbered 1..N with none skipped or repeated.
#
# INTEGRITY. The manifest reviewer/MANIFEST.sha256 is REQUIRED, must list exactly PKG_FILES plus
# reviewer/PACKAGE_VERSION, each once, and every file must match it, before step 1. The one
# exception is a repository checkout, which has no manifest: run it with --source-checkout, and
# with neither marker file present the check says PACKAGE_MANIFEST=SKIPPED. Without that option a
# directory with no manifest FAILS.
#
# MODES
#   bash reviewer/selfcheck.sh                  run every step; REVIEWER_PACKAGE=PASS|FAIL|ERROR
#   bash reviewer/selfcheck.sh --times FILE     the same, and write step<TAB>wall_s<TAB>peak_rss_kib
#   bash reviewer/selfcheck.sh --keep           the same, and keep the scratch directory
#   bash reviewer/selfcheck.sh --source-checkout  the same, in a repository checkout (no manifest)
#   bash reviewer/selfcheck.sh --list           print the steps as parsed, run nothing
#   bash reviewer/selfcheck.sh --files          print the package's input files, one per line
#   bash reviewer/selfcheck.sh --aggregates [RUN13LOG]
#        the layer-B check (step 13): the 31-row aggregate table against the published full-31
#        run log, and, if RUN13LOG is given, the n=13 column against that engine log
#   bash reviewer/selfcheck.sh --selftest       show that each check can fail, one planted defect
#                                               at a time (no compiler; a few seconds)
#   --readme FILE                               grade another copy of the page (any run mode)
#
# VERDICT TOKENS, each a whole line:
#   REVIEWER_PACKAGE=PASS|FAIL|ERROR      exit 0 | 1 | 2
#   PACKAGE_MANIFEST=OK|FAIL|SKIPPED|ERROR
#   SELFCHECK_STEPS=<n>  SELFCHECK_FAILED=<n>  SELFCHECK_UNFINISHED=<n>  (timed out or crashed)
#   AGGREGATES=PASS|FAIL|ERROR            --aggregates, exit 0 | 1 | 2 (ERROR: the check crashed)
#   SELFCHECK_SELFTEST=PASS|FAIL          --selftest, exit 0 | 1
#
# NEEDS: bash, python3 (3.8 or later; no third-party packages), GNU coreutils, findutils, sed, awk,
# grep and gzip, and for the steps themselves gcc with OpenMP and the zlib headers; --selftest also
# needs cmp and diff (GNU diffutils). The scratch directory (${TMPDIR:-/tmp}) must allow running
# programs, since the steps run binaries built there. GNU time
# (/usr/bin/time) is used for peak memory if present and is optional. No network, no git.
#
# Developed with AI assistance (Claude, Anthropic).
set -uo pipefail

# ---- the package's input files: the one list (make_package.sh reads it with --files) -------------
PKG_FILES=(
  reviewer/README.md
  reviewer/selfcheck.sh
  reviewer/make_package.sh
  solve.c
  verify.c
  verify.py
  documentation/REPRODUCE.md
  documentation/SPECIFICATION.md
  reports/FULL31_EXACT_AGGREGATES.md
  scripts/reproduce_digests_gate.sh
  runs/20260716_f1c5_c1c2c4c5_d128westus3/run.out
  LICENSE.md
  CITATION.cff
)

ORIG_PWD=$PWD
ROOT=$(cd "$(dirname "$0")/.." && pwd) || { echo "REVIEWER_PACKAGE=ERROR"; exit 2; }
README="$ROOT/reviewer/README.md"
MODE=run TIMES="" KEEP=0 RUN13="" CHECKOUT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --readme)     README=${2:-}; shift 2 || shift
                  case "$README" in /*|'') ;; *) README="$ORIG_PWD/$README" ;; esac ;;
    --times)      TIMES=${2:-}; shift 2 || shift
                  case "$TIMES" in /*|'') ;; *) TIMES="$ORIG_PWD/$TIMES" ;; esac ;;
    --keep)       KEEP=1; shift ;;
    --source-checkout) CHECKOUT=1; shift ;;
    --list)       MODE=list; shift ;;
    --files)      MODE=files; shift ;;
    --selftest)   MODE=selftest; shift ;;
    --aggregates) MODE=aggregates; shift
                  if [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then
                    RUN13=$1; shift
                    case "$RUN13" in /*) ;; *) RUN13="$ORIG_PWD/$RUN13" ;; esac
                  fi ;;
    *) echo "usage: $0 [--readme FILE] [--times FILE] [--keep] [--source-checkout] | --list | --files | --aggregates [RUN13LOG] | --selftest"
       echo "REVIEWER_PACKAGE=ERROR"; exit 2 ;;
  esac
done

# ---- pinned values for the layer-B check ---------------------------------------------------------
# These are the published values the aggregate check compares against. Each one is also printed in
# reviewer/README.md, and each was computed from the files named, not copied from prose.
AGG_DOC_REL="reports/FULL31_EXACT_AGGREGATES.md"
RUNOUT_REL="runs/20260716_f1c5_c1c2c4c5_d128westus3/run.out"
RUNOUT_SHA="8c7d063e21a388b8a09f91a44dff36ffe0071c4e2737b1f50f34781a73260655"
TABLE_SHA="165cda4e804e398a1d3690cf1d73348d7ddd743134a61c84ba99df8b38881547"
TERMINAL="1097051278789181790036112071176579186688"

# ---- a checker's verdict: its exit status AND exactly one verdict line ---------------------------
# verdict_gate KEY RC OUT PASSVALS FAILVALS WHAT -> prints OUT without its KEY= lines, then ONE KEY=
# line, and returns 0 when RC is 0 and OUT held exactly one KEY= line with a value in PASSVALS, 1
# when RC is 1 and OUT held exactly one with a value in FAILVALS, and otherwise (a crash, a kill, a
# timeout, no verdict line, two of them, or a verdict that disagrees with the exit status) prints
# [ERROR] and KEY=ERROR and returns 2. (The Q-951 / Q-952 class, batch 39: a verdict read from a
# line alone, or from an exit status alone, can be a crash's leftover.)
verdict_gate(){
  local key=$1 rc=$2 out=$3 pv=" $4 " fv=" $5 " what=$6 toks n v
  toks=$(grep -E "^${key}=" <<<"$out")
  n=$(grep -c . <<<"$toks")
  grep -vE "^${key}=" <<<"$out"
  v=${toks#"$key="}
  if [ "$n" -eq 1 ] && [ "$rc" -eq 0 ] && [[ "$pv" == *" $v "* ]]; then echo "$toks"; return 0; fi
  if [ "$n" -eq 1 ] && [ "$rc" -eq 1 ] && [[ "$fv" == *" $v "* ]]; then echo "$toks"; return 1; fi
  echo "  [ERROR] $what did not finish cleanly (exit $rc, $n $key= line(s)$([ "$n" -gt 0 ] && printf ': %s' "$(tr '\n' ' ' <<<"$toks")")); its verdict is not evidence"
  echo "$key=ERROR"; return 2
}

# ---- the aggregate check (layer B) ---------------------------------------------------------------
# aggregates DOC RUNOUT [RUN13LOG [LOG_SHA TABLE_SHA TERMINAL]] -> prints its legs and
# AGGREGATES=PASS|FAIL|ERROR; returns 0|1|2. The last three default to the pinned values; --selftest
# passes others so that each planted defect is caught by the check it targets and not by a digest.
# The verdict is the checker's exit status AND its one verdict line (verdict_gate): a crash, a kill
# or a verdict line that disagrees with the exit status is AGGREGATES=ERROR, never PASS or FAIL.
# Numbers are matched as ASCII digits only ([0-9], not Python's Unicode \d) and compared as exact
# strings or Python integers, never as floating point (the P-01 / Q-948 class; batch 39).
aggregates(){
  local out rc
  out=$(python3 - "$1" "$2" "${3:-}" "${4:-$RUNOUT_SHA}" "${5:-$TABLE_SHA}" "${6:-$TERMINAL}" 2>&1 <<'PY'
import hashlib, math, re, sys
doc, runout, run13, want_log_sha, want_table_sha, terminal = sys.argv[1:7]
bad = []
def leg(ok, msg):
    print(("  [ok]    " if ok else "  [FAIL]  ") + msg)
    if not ok:
        bad.append(msg)

def section_rows(n_sec, width):
    rows, sec = [], False
    try:
        fh = open(doc, encoding="utf-8")
    except OSError as e:
        leg(False, "cannot read %s: %s" % (doc, e)); return rows
    for l in fh:
        if l.startswith("## "):
            sec = l.startswith("## %d." % n_sec)
            continue
        if sec and l.startswith("|"):
            c = [x.strip().replace(",", "") for x in l.strip().strip("|").split("|")]
            if len(c) == width:
                rows.append(c)
    return rows

# (1) the 31-row table of section 1
t = [c for c in section_rows(1, 8) if re.fullmatch(r"[0-9]+", c[0])]
leg([int(c[0]) for c in t] == list(range(1, 32)),
    "section 1 of the aggregates page has rows k = 1..31 (found %d)" % len(t))
canon = "".join("\t".join(c) + "\n" for c in t)
tsha = hashlib.sha256(canon.encode()).hexdigest()
print("AGGREGATES_TABLE_SHA256=" + tsha)
leg(tsha == want_table_sha, "the table digest is the published one (%s...)" % want_table_sha[:16])
for c in t:
    k = int(c[0])
    if not re.fullmatch(r"[0-9]+", c[2]) or int(c[2]) != math.comb(31, k):
        leg(False, "k=%d: the table's C(31,k) cell %s is not %d" % (k, c[2], math.comb(31, k)))

# (2) the published full-31 run log. Every record of each kind must be well formed, about the
# full-31 problem, and unambiguous; a record that does not parse is a failure, never skipped.
try:
    raw = open(runout, "rb").read()
except OSError as e:
    raw = b""
    leg(False, "cannot read the run log %s: %s" % (runout, e))
lsha = hashlib.sha256(raw).hexdigest()
leg(lsha == want_log_sha, "the run log's sha256 is the published one (%s...)" % want_log_sha[:16])
text = raw.decode("utf-8", "replace")
# A full-31 session line names the whole problem: all 31 pairs in order, starting exit 0.
FULL31_RUN = "[f1c5] run: FULL-31 n=31 pairs [%s] start_exit=0 " % ",".join(str(i) for i in range(1, 32))
pat = re.compile(r"^\[f1c5\] layer k=\s*([0-9]+)/31: canonical_masks=([0-9]+) \(of C\(31,([0-9]+)\)=([0-9]+)\) "
                 r"states=([0-9]+) entries=([0-9]+) V_k=([0-9]+) bytes=([0-9.]+)GB .*? mass=([0-9]+) ")
log, dup, malformed = {}, [], []
runs_other, n_runs = [], 0
finals, finals_bad = [], []
for i, line in enumerate(text.split("\n"), 1):
    if line.startswith("[f1c5] layer k="):
        m = pat.match(line)
        if not m or m.group(1) != m.group(3):
            malformed.append(i); continue
        k = int(m.group(1))
        if k in log:
            dup.append(k); continue          # the FIRST record of a k is the one compared
        g = m.groups()
        log[k] = [g[0], g[1], g[3], g[4], g[5], g[6], g[7], g[8]]
        if int(g[3]) != math.comb(31, k):
            leg(False, "k=%d: the run log's C(31,k) field %s is not %d" % (k, g[3], math.comb(31, k)))
    elif line.startswith("[f1c5] run:"):
        n_runs += 1
        if not line.startswith(FULL31_RUN):
            runs_other.append(i)
    elif line.startswith("F1C5 EXACT"):
        m = re.fullmatch(r"F1C5 EXACT \|C1 & C2 & C4 & C5\| = ([0-9]+)", line)
        if m:
            finals.append(m.group(1))
        elif not line.startswith("F1C5 EXACT: DONE"):
            finals_bad.append(i)
leg(not malformed, "every layer record of the run log is a well-formed full-31 record%s"
    % ("" if not malformed else " (malformed at line %s)" % malformed[:5]))
leg(not dup, "no layer appears twice in the run log%s" % ("" if not dup else " (repeated k = %s)" % dup[:5]))
leg(sorted(log) == list(range(1, 32)), "the run log has a layer record for each k = 1..31 (found %d)" % len(log))
leg(n_runs >= 1 and not runs_other, "every run session in the log is the full-31 problem%s"
    % ("" if not runs_other else " (other problem at line %s)" % runs_other[:5]))
mism = 0
for c in t:
    k = int(c[0])
    if k not in log:
        continue
    g = log[k]
    # table: k cm C states entries Vk GB mass ; log: k cm C states entries Vk GB mass
    for name, a, b in (("canonical_masks", c[1], g[1]), ("C(31,k)", c[2], g[2]), ("states", c[3], g[3]),
                       ("entries", c[4], g[4]), ("V_k", c[5], g[5]), ("layer GB", c[6], g[6]),
                       ("mass", c[7], g[7])):
        if a != b:
            mism += 1
            leg(False, "k=%d %s: table %s, run log %s" % (k, name, a, b))
leg(mism == 0 and len(t) == 31 and len(log) == 31,
    "all 7 columns of all 31 rows equal the run log (%d disagreements)" % mism)
leg(bool(finals) and not finals_bad and all(f == terminal for f in finals),
    "every final-count line of the run log reads %s (%d such lines%s)"
    % (terminal, len(finals), "" if not finals_bad else ", malformed at line %s" % finals_bad[:5]))
leg(len(t) == 31 and t[-1][7] == terminal, "row k=31 of the table is the published total")
leg(len(t) == 31 and bool(re.fullmatch(r"[0-9]+", t[-1][7])) and int(t[-1][7]) % 24 == 0,
    "the total is divisible by 24 (a consistency check: the order-24 group acts freely)")

# (3) optional: the reader's own n=13 engine log against the n=13 column of section 2.
# The log must hold exactly one n=13 run of the published problem: one start line and one end line
# naming the published pair list and starting exit 0, the end line with the published B0, one
# total, every layer record well formed for n=13, each k once, in increasing order.
# (Codex PKG-V3 finding 7, 2026-10-03: a log with another pair list, or with two layer records
# swapped, passed; and section 2's column kept the first of two rows for a layer, finding 5.)
if run13:
    P13 = "[3,7,11,5,8,26,31,10,15,20,23,27,29]"
    col, colbad = {}, []
    for c in section_rows(2, 8) + section_rows(2, 5):
        if len(c) > 4 and re.fullmatch(r"[0-9]+", c[3]):
            k = int(c[3])
            if not 1 <= k <= 13 or not re.fullmatch(r"[0-9]+", c[4]) or k in col:
                colbad.append(k); continue
            col[k] = int(c[4])
    try:
        r13 = open(run13, encoding="utf-8", errors="replace").read().split("\n")
    except OSError as e:
        r13 = []
        leg(False, "cannot read %s: %s" % (run13, e))
    p13 = re.compile(r"^\[f1c5\] layer k=\s*([0-9]+)/13: canonical_masks=([0-9]+) \(of C\(13,([0-9]+)\)=([0-9]+)\) "
                     r"states=[0-9]+ entries=[0-9]+ V_k=[0-9]+ bytes=[0-9.]+GB .*? mass=([0-9]+) ")
    eng, dup13, bad13 = {}, [], []
    starts, ends, totals, at = [], [], [], {}
    for i, line in enumerate(r13, 1):
        if line.startswith("[f1c5] layer k="):
            m = p13.match(line)
            if not m or m.group(1) != m.group(3) or int(m.group(4)) != math.comb(13, int(m.group(1))):
                bad13.append(i); continue
            k = int(m.group(1))
            if k in eng:
                dup13.append(k); continue
            eng[k] = int(m.group(5)); at[k] = i
        elif line.startswith("[f1c5] run:"):
            starts.append((i, line))
        elif line.startswith("F1C5 SUBSET n=") and "pairs" in line:
            ends.append((i, line))
        elif "orbit-quotient C5-DP total" in line:
            m = re.fullmatch(r"\s*orbit-quotient C5-DP total = ([0-9]+)", line)
            totals.append((i, int(m.group(1)) if m else None))
    leg(sorted(col) == list(range(1, 14)) and not colbad,
        "section 2 has exactly one well-formed n=13 mass for each k = 1..13%s"
        % ("" if not colbad else " (bad or repeated row at k = %s)" % colbad[:5]))
    leg(len(starts) == 1 and starts[0][1].startswith("[f1c5] run: SUBSET n=13 pairs %s start_exit=0 " % P13)
        and len(ends) == 1 and ends[0][1] == "F1C5 SUBSET n=13 pairs %s start_exit=0 B0=(1,6,0,6,0)" % P13
        and len(totals) == 1,
        "your n=13 log holds exactly one n=13 run of the published pairs %s from exit 0 (start lines %d, end lines %d, totals %d)"
        % (P13, len(starts), len(ends), len(totals)))
    leg(not bad13, "every layer record of your n=13 log is a well-formed n=13 record%s"
        % ("" if not bad13 else " (malformed at line %s)" % bad13[:5]))
    leg(not dup13, "no layer appears twice in your n=13 log%s" % ("" if not dup13 else " (repeated k = %s)" % dup13[:5]))
    leg(sorted(eng) == list(range(1, 14)), "your n=13 log has a layer record for k = 1..13 (found %d)" % len(eng))
    if starts and ends and totals and eng:
        lo, hi = min(at.values()), max(at.values())
        inorder = [at[k] for k in sorted(at)] == sorted(at.values())
        leg(starts[0][0] < lo and hi < ends[0][0] < totals[-1][0] and inorder,
            "your n=13 log is in run order: start, layers k = 1..13 in turn, end line, total")
    d13 = [k for k in range(1, 14) if eng.get(k) != col.get(k)]
    leg(not d13, "your n=13 engine masses equal section 2's n=13 column at every layer%s"
        % ("" if not d13 else " (differ at k = %s)" % d13))
    tot = totals[0][1] if len(totals) == 1 else None
    leg(tot is not None and tot == eng.get(13) == col.get(13) == 2063395607040,
        "your n=13 total is 2063395607040 and equals your k=13 layer and the column's last row")

print("AGGREGATES=" + ("FAIL" if bad else "PASS"))
sys.exit(1 if bad else 0)
PY
); rc=$?
  verdict_gate AGGREGATES "$rc" "$out" PASS FAIL "the aggregate check"
}

# ---- the package manifest ------------------------------------------------------------------------
# check_manifest DIR [CHECKOUT] -> prints its legs and PACKAGE_MANIFEST=OK|FAIL|SKIPPED|ERROR;
# returns 0|1|0|2 (ERROR: the checker crashed or its verdict line and exit status disagree). The manifest is required unless CHECKOUT is 1 (--source-checkout) AND neither marker file
# is present. (Before 2026-10-03 a directory with neither marker was taken to be a checkout and
# skipped, so deleting both files from a package switched the integrity check off; Codex PKG-V3
# finding 8.)
check_manifest(){
  local d=$1 checkout=${2:-0}
  if [ ! -e "$d/reviewer/PACKAGE_VERSION" ] && [ ! -e "$d/reviewer/MANIFEST.sha256" ]; then
    if [ "$checkout" = 1 ]; then
      echo "  [note]  --source-checkout: no reviewer/MANIFEST.sha256, so file integrity is not checked"
      echo "PACKAGE_MANIFEST=SKIPPED"; return 0
    fi
    echo "  [FAIL]  no reviewer/MANIFEST.sha256 and no reviewer/PACKAGE_VERSION: this is not an intact package"
    echo "          (in a repository checkout, run with --source-checkout)"
    echo "PACKAGE_MANIFEST=FAIL"; return 1
  fi
  local out rc
  out=$(python3 - "$d" "${PKG_FILES[@]}" reviewer/PACKAGE_VERSION 2>&1 <<'PY'
import hashlib, os, re, sys
d, want = sys.argv[1], sys.argv[2:]
bad = []
def fail(msg):
    print("  [FAIL]  " + msg); bad.append(msg)
mp = os.path.join(d, "reviewer", "MANIFEST.sha256")
try:
    lines = open(mp, encoding="utf-8").read().split("\n")
except OSError as e:
    lines = None
    fail("the package has no readable reviewer/MANIFEST.sha256 (%s)" % e.strerror)
if lines is not None:
    if lines and lines[-1] == "":
        lines.pop()
    seen = {}
    for i, l in enumerate(lines, 1):
        m = re.fullmatch(r"([0-9a-f]{64})  (\S+)", l)
        if not m:
            fail("manifest line %d is not '<sha256>  <path>'" % i); continue
        if m.group(2) in seen:
            fail("manifest lists %s more than once" % m.group(2)); continue
        seen[m.group(2)] = m.group(1)
    for p in want:
        if p not in seen:
            fail("the manifest does not list %s" % p)
    for p in sorted(set(seen) - set(want)):
        fail("the manifest lists %s, which is not a package file" % p)
    for p in want:
        if p not in seen:
            continue
        try:
            h = hashlib.sha256(open(os.path.join(d, p), "rb").read()).hexdigest()
        except OSError as e:
            fail("%s is missing (%s)" % (p, e.strerror)); continue
        if h != seen[p]:
            fail("%s differs from the manifest" % p)
if not bad:
    print("  [ok]    the manifest lists exactly the %d package files, and every one matches it" % len(want))
print("PACKAGE_MANIFEST=" + ("FAIL" if bad else "OK"))
sys.exit(1 if bad else 0)
PY
); rc=$?
  verdict_gate PACKAGE_MANIFEST "$rc" "$out" OK FAIL "the manifest check"
}

# ---- the step parser -----------------------------------------------------------------------------
# parse README -> TSV records: STATED<TAB>n, STEP<TAB>n<TAB>command, EXPECT<TAB>n<TAB>text,
# ERROR<TAB>message.
parse(){
  python3 - "$1" <<'PY'
import re, sys
def out(*a): print("\t".join(str(x) for x in a))
try:
    lines = open(sys.argv[1], encoding="utf-8").read().split("\n")
except (OSError, UnicodeDecodeError) as e:
    out("ERROR", "cannot read the page: %s" % e); sys.exit(0)
stated = [int(m.group(1)) for l in lines for m in [re.search(r"There are \*\*(\d+) steps\*\*", l)] if m]
if len(stated) != 1:
    out("ERROR", "the page must state its step count exactly once as 'There are **N steps**' (found %d)" % len(stated))
else:
    out("STATED", stated[0])
start = next((i for i, l in enumerate(lines) if l.startswith("## The steps")), None)
if start is None:
    out("ERROR", "the page has no '## The steps' section"); sys.exit(0)
fence, cur = False, None
for l in lines[start + 1:]:
    if l.startswith("## "):
        break
    if l.startswith("```"):
        fence = not fence
        continue
    if not fence:
        continue
    m = re.match(r"^\[(\d+)\] (.+)$", l)
    if m:
        cur = int(m.group(1)); out("STEP", cur, m.group(2).rstrip()); continue
    m = re.match(r"^\s+expect: (.+)$", l)
    if m and cur is not None:
        out("EXPECT", cur, m.group(1).rstrip()); continue
PY
}

# check_page PAGE -> validates the parsed page; prints problems; sets STEPS_TSV; returns 0|1|2
check_page(){
  STEPS_TSV=$(parse "$1") || { echo "  [ERROR] the step parser did not run (python3 failed)"; return 2; }
  if grep -q '^ERROR' <<<"$STEPS_TSV"; then
    awk -F'\t' '/^ERROR/{print "  [ERROR] " $2}' <<<"$STEPS_TSV"; return 2
  fi
  local stated nums
  stated=$(awk -F'\t' '/^STATED/{print $2}' <<<"$STEPS_TSV")
  nums=$(awk -F'\t' '/^STEP/{printf "%s ", $2}' <<<"$STEPS_TSV")
  local want; want=$(seq 1 "$stated" 2>/dev/null | tr '\n' ' ')
  if [ -z "$nums" ] || [ "$nums" != "$want" ]; then
    echo "  [FAIL]  the page states $stated steps; its numbered steps are: ${nums:-none}"
    return 1
  fi
  local n
  for n in $nums; do
    if ! awk -F'\t' -v n="$n" '$1=="EXPECT" && $2==n{f=1} END{exit !f}' <<<"$STEPS_TSV"; then
      echo "  [FAIL]  step $n has no expect: line; a step that is not checked certifies nothing"
      return 1
    fi
  done
  return 0
}

# ---- one expectation against one step's output -----------------------------------------------------
# match_expect TRIMMED_LOG EXPECTATION -> 0 if it matches; else prints the reason and returns 1.
match_expect(){
  local f=$1 exp=$2
  case "$exp" in
    *" …")
      local pre=${exp% …}
      if ! P=$pre awk 'BEGIN{p = ENVIRON["P"]} index($0, p) == 1 && (length($0) == length(p) || substr($0, length(p) + 1, 1) == " ") {f=1} END{exit !f}' "$f"; then
        echo "          [FAIL] no output line begins with: $pre"; return 1
      fi ;;
    *)
      if ! grep -qxF -- "$exp" "$f"; then
        echo "          [FAIL] no output line is exactly: $exp"; return 1
      fi ;;
  esac
  if [[ "$exp" =~ ^([A-Za-z0-9_]+)=[^[:space:]]+$ ]]; then
    local key=${BASH_REMATCH[1]} other
    other=$(grep -E "^${key}=" "$f" | grep -vxF -- "$exp" | head -1)
    if [ -n "$other" ]; then
      echo "          [FAIL] conflicting verdict: '$other' beside the expected '$exp'"; return 1
    fi
    # Exactly one verdict line (the Q-952 class, batch 39): two runs' worth of tokens in one log, or
    # a producer that printed its verdict twice, is not one result.
    local nsame; nsame=$(grep -cxF -- "$exp" "$f")
    if [ "$nsame" -ne 1 ]; then
      echo "          [FAIL] the verdict line '$exp' appears $nsame times; a verdict must be printed exactly once"; return 1
    fi
  fi
  return 0
}

# ---- contradicting lines beside a matched expectation ----------------------------------------------
# conflict_check TRIMMED_LOG EXPECT_FILE -> 0 if no line contradicts the step; else prints each
# reason and returns 1. Two rules (Codex PKG-V3 finding 4: the right line followed by a wrong one
# passed, e.g. the right sha256 and then "[--selftest] FAIL — sha mismatch!", or the right count
# and then "KC COUNT n=13 = 1"):
#  (1) SAME FORM, OTHER VALUE. Write a line's "form" by replacing every number (and every run of
#      16+ hex digits) with #. A line that has the form of a matched expectation, but not its text,
#      contradicts it. When the form holds two or more numbers, the first one is taken as a label
#      (a layer index, say) and must also agree, so "layer 1: ..." does not contradict "layer 9: ...".
#      For an expectation ending in " …", the form of its text before " …" is compared with the
#      start of each line. KEY=VALUE expectations are left to the KEY= rule in match_expect.
#  (2) A REPORTED FAILURE. A line containing the word FAIL or ERROR, a starred MISMATCH, or the
#      start of a Python traceback fails the step, unless it is exactly an expected line (for a
#      " …" expectation: unless the word is inside the expected prefix, not in what follows it), or
#      a KEY= line already judged by the KEY= rule. The checker's own crash is exit 3, which the
#      runner reports as [ERROR], never as a pass.
conflict_check(){
  python3 - "$1" "$2" <<'PY'
import os, re, sys, traceback
def _crash(t, v, tb):                  # a crash is exit 3, never read as "no conflict" or "a conflict"
    traceback.print_exception(t, v, tb); sys.stdout.flush(); sys.stderr.flush(); os._exit(3)
sys.excepthook = _crash
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().split("\n")
exps = [e for e in open(sys.argv[2], encoding="utf-8").read().split("\n") if e]
NUM = re.compile(r"[0-9a-f]{16,}|\d+(?:,\d+)*")
def form(s): return NUM.sub("#", s), NUM.findall(s)
def matches(e, l):
    if e.endswith(" …"):
        p = e[:-2]
        return l == p or l.startswith(p + " ")
    return l == e
kv = re.compile(r"^([A-Za-z0-9_]+)=\S+$")
keys = {kv.match(e).group(1) for e in exps if kv.match(e)}
bad = 0
for e in exps:
    if kv.match(e) or not any(matches(e, l) for l in lines):
        continue                       # KEY= rule, or already failed as missing
    pre = e[:-2] if e.endswith(" …") else e
    ef, en = form(pre)
    for l in lines:
        if matches(e, l):
            continue
        lf, ln = form(l)
        if e.endswith(" …"):
            same = lf == ef or lf.startswith(ef + " ")
        else:
            same = lf == ef
        if same and len(en) >= 2 and ln[:1] != en[:1]:
            same = False               # a different label: another record, not a contradiction
        if same:
            print("          [FAIL] conflicting line: '%s' beside the expected '%s'" % (l, e)); bad = 1
fail = re.compile(r"(?<![A-Za-z])(?:FAIL|ERROR)(?![A-Za-z])|\*\s*MISMATCH\s*\*|^Traceback \(most recent call last\):")
for l in lines:
    if not fail.search(l) or any(not e.endswith(" …") and l == e for e in exps):
        continue                       # no failure word, or the page asks for exactly this line
    # A line that only BEGINS with an expected prefix is exempt only if the failure word is inside
    # that prefix: "<expected prefix> ... FAIL" reports a failure (batch 39; before, any line that
    # matched a " …" expectation was exempt, whatever followed the prefix).
    if any(e.endswith(" …") and matches(e, l) and not fail.search(l[len(e) - 2:]) for e in exps):
        continue
    m = re.match(r"^([A-Za-z0-9_]+)=", l)
    if m and m.group(1) in keys:
        continue
    print("          [FAIL] the output reports a failure: '%s'" % l); bad = 1
sys.exit(bad)
PY
}

# ---- the runner ----------------------------------------------------------------------------------
# populate DEST SRC FILE... -> copies each listed file from SRC into DEST (and nothing else).
populate(){
  local dest=$1 src=$2 f; shift 2
  for f in "$@"; do
    [ -f "$src/$f" ] || { echo "  [ERROR] package file missing: $f"; return 1; }
    mkdir -p "$dest/$(dirname "$f")" && cp -p "$src/$f" "$dest/$f" || { echo "  [ERROR] cannot copy $f"; return 1; }
  done
}

# run_steps PAGE SRC FILE... -> runs every step of PAGE in a fresh scratch directory holding copies
# of the listed files of SRC; sets SCRATCH NSTEP NFAIL NUNFIN; returns 0, or 2 if the scratch cannot
# be made. NUNFIN counts the steps that did not finish: a timeout (exit 124: [TIMEOUT]), a kill by a
# signal (exit 129..192: [CRASH]) or a crash of the contradiction check itself ([ERROR]). Such a
# step is also counted in NFAIL, and the run's verdict is then ERROR, never PASS or FAIL (the Q-951
# class, batch 39: before, a timeout was an ordinary "exit status 124").
run_steps(){
  local page=$1 src=$2 W n cmd t0 t1 rc crc log ok unfin rss exp state; shift 2
  W=$(mktemp -d "${TMPDIR:-/tmp}/roae_reviewer.XXXXXX") || return 2
  SCRATCH=$W
  populate "$W" "$src" "$@" || return 2
  mkdir -p "$W/.selfcheck"
  # The page's commands set every engine setting they need; inherited SOLVE_* values are cleared.
  local UNSET=() v
  for v in $(compgen -e | grep '^SOLVE_'); do UNSET+=(-u "$v"); done
  local TIMEBIN=""
  if [ -x /usr/bin/time ] && /usr/bin/time -f '%M' -o /dev/null true 2>/dev/null; then TIMEBIN=/usr/bin/time; fi
  [ -n "$TIMES" ] && printf 'step\twall_s\tpeak_rss_kib\tresult\n' > "$TIMES"
  NSTEP=0; NFAIL=0; NUNFIN=0
  local tmo=${SELFCHECK_STEP_TIMEOUT:-1800}
  while IFS=$'\t' read -r _ n cmd; do
    NSTEP=$((NSTEP+1))
    log="$W/.selfcheck/step_$n.log"
    printf '  step %2s  %s\n' "$n" "$cmd"
    t0=$(date +%s%N)
    if [ -n "$TIMEBIN" ]; then
      (cd "$W" && env "${UNSET[@]}" "$TIMEBIN" -f '%M' -o "$W/.selfcheck/rss_$n" \
          timeout "$tmo" bash -o pipefail -c "$cmd") >"$log" 2>&1; rc=$?
      rss=$(tail -1 "$W/.selfcheck/rss_$n" 2>/dev/null | grep -E '^[0-9]+$' || echo "")
    else
      (cd "$W" && env "${UNSET[@]}" timeout "$tmo" bash -o pipefail -c "$cmd") >"$log" 2>&1; rc=$?
      rss=""
    fi
    t1=$(date +%s%N)
    local wall; wall=$(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.2f", (b-a)/1e9}')
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$log" > "$log.trim"
    ok=1; unfin=0
    if [ "$rc" -eq 124 ]; then
      echo "          [TIMEOUT] the step did not finish within $tmo s (SELFCHECK_STEP_TIMEOUT; exit 124): nothing it printed is evidence"
      ok=0; unfin=1
    elif [ "$rc" -gt 128 ] && [ "$rc" -le 192 ]; then
      echo "          [CRASH] the step was killed by signal $((rc - 128)) (exit $rc): nothing it printed is evidence"
      ok=0; unfin=1
    elif [ "$rc" -ne 0 ]; then
      echo "          [FAIL] exit status $rc"; ok=0
    fi
    while IFS=$'\t' read -r _ _ exp; do
      match_expect "$log.trim" "$exp" || ok=0
    done < <(awk -F'\t' -v n="$n" '$1=="EXPECT" && $2==n' <<<"$STEPS_TSV")
    awk -F'\t' -v n="$n" '$1=="EXPECT" && $2==n{print $3}' <<<"$STEPS_TSV" > "$log.exp"
    conflict_check "$log.trim" "$log.exp"; crc=$?
    case "$crc" in
      0) ;;
      1) ok=0 ;;
      *) echo "          [ERROR] the contradiction check itself failed (exit $crc), so this step is unchecked"; ok=0; unfin=1 ;;
    esac
    NUNFIN=$((NUNFIN + unfin))
    if [ "$ok" -eq 1 ]; then
      printf '          [ok] %s s%s\n' "$wall" "${rss:+, peak ${rss} KiB}"
    else
      NFAIL=$((NFAIL+1)); echo "          last lines of its output:"; tail -4 "$log" | sed 's/^/          | /'
    fi
    state=ok; [ "$ok" -eq 1 ] || state=FAIL
    [ "$rc" -eq 124 ] && state=TIMEOUT
    [ "$rc" -gt 128 ] && [ "$rc" -le 192 ] && state=CRASH
    [ -n "$TIMES" ] && printf '%s\t%s\t%s\t%s\n' "$n" "$wall" "$rss" "$state" >> "$TIMES"
  done < <(grep '^STEP' <<<"$STEPS_TSV")
  return 0
}

cleanup(){
  if [ -n "${SCRATCH:-}" ] && [ "$KEEP" -eq 0 ] && [ -d "$SCRATCH" ]; then rm -rf -- "$SCRATCH"; fi
  if [ -n "${SD:-}" ] && [ -d "$SD" ]; then rm -rf -- "$SD"; fi
}
trap cleanup EXIT

case "$MODE" in
files)
  printf '%s\n' "${PKG_FILES[@]}"; exit 0 ;;
aggregates)
  echo "== layer B: the full-31 aggregate table =="
  aggregates "$ROOT/$AGG_DOC_REL" "$ROOT/$RUNOUT_REL" "$RUN13"; exit $? ;;
list)
  check_page "$README"; r=$?
  printf '%s\n' "$STEPS_TSV" | awk -F'\t' '$1=="STEP"{printf "[%s] %s\n", $2, $3} $1=="EXPECT"{printf "      expect: %s\n", $3} $1=="STATED"{printf "stated: %s steps\n", $2}'
  exit $r ;;
run)
  echo "== ROAE reviewer package: self-check =="
  [ -r "$ROOT/reviewer/PACKAGE_VERSION" ] && sed 's/^/  /' "$ROOT/reviewer/PACKAGE_VERSION"
  check_manifest "$ROOT" "$CHECKOUT"; r=$?
  if [ "$r" -eq 2 ]; then echo "REVIEWER_PACKAGE=ERROR"; exit 2; fi
  if [ "$r" -ne 0 ]; then echo "REVIEWER_PACKAGE=FAIL"; exit 1; fi
  miss=""
  for t in gcc python3 sha256sum find xargs sort tee timeout mktemp awk sed grep gzip cut head tail cp; do
    command -v "$t" >/dev/null 2>&1 || miss="$miss $t"
  done
  if [ -n "$miss" ]; then echo "  [ERROR] missing tools:$miss"; echo "REVIEWER_PACKAGE=ERROR"; exit 2; fi
  if ! printf '#include <zlib.h>\n' | gcc -E -x c - >/dev/null 2>&1; then
    echo "  [ERROR] the zlib headers are missing (Debian/Ubuntu: zlib1g-dev; Fedora: zlib-devel)"
    echo "REVIEWER_PACKAGE=ERROR"; exit 2
  fi
  check_page "$README"; r=$?
  if [ "$r" -eq 2 ]; then echo "REVIEWER_PACKAGE=ERROR"; exit 2; fi
  if [ "$r" -ne 0 ]; then echo "REVIEWER_PACKAGE=FAIL"; exit 1; fi
  echo "  $(awk -F'\t' '/^STATED/{print $2}' <<<"$STEPS_TSV") steps, run in a fresh scratch directory holding copies of the ${#PKG_FILES[@]} package files only"
  run_steps "$README" "$ROOT" "${PKG_FILES[@]}" || { echo "REVIEWER_PACKAGE=ERROR"; exit 2; }
  [ "$KEEP" -eq 1 ] && echo "  scratch kept: $SCRATCH"
  echo "SELFCHECK_STEPS=$NSTEP"
  echo "SELFCHECK_FAILED=$NFAIL"
  echo "SELFCHECK_UNFINISHED=$NUNFIN"
  if [ "$NUNFIN" -gt 0 ]; then
    echo "  [ERROR] $NUNFIN step(s) did not finish (timeout, crash, or a crash of the check itself): the run is incomplete"
    echo "REVIEWER_PACKAGE=ERROR"; exit 2
  fi
  if [ "$NFAIL" -eq 0 ] && [ "$NSTEP" -gt 0 ]; then echo "REVIEWER_PACKAGE=PASS"; exit 0; fi
  echo "REVIEWER_PACKAGE=FAIL"; exit 1 ;;
esac

# ---- --selftest: each check must be able to fail, for its own reason -----------------------------
# Every leg plants ONE defect and asserts (a) the verdict and (b) that EVERY failure line it caused
# matches the check the leg targets, so a defect caught by some other check (a digest, say) cannot
# stand in for the check under test. Fixtures assert that their plant landed.
echo "== ROAE reviewer package: --selftest =="
SD=$(mktemp -d "${TMPDIR:-/tmp}/roae_reviewer_self.XXXXXX") || { echo "SELFCHECK_SELFTEST=FAIL"; exit 1; }
sfail=0
DOC="$ROOT/$AGG_DOC_REL"; LOG="$ROOT/$RUNOUT_REL"
sha(){ sha256sum "$1" | cut -d' ' -f1; }
tsha(){ aggregates "$1" "$LOG" "" 2>/dev/null | sed -n 's/^AGGREGATES_TABLE_SHA256=//p'; }
stub(){ mkdir -p "$(dirname "$1")"; printf '#!/usr/bin/env bash\n%s\n' "$2" > "$1"; chmod +x "$1"; }
landed(){ if cmp -s "$1" "$2"; then echo "  [FAIL]  fixture $3: the plant did not land"; sfail=1; return 1; fi; }

# grade NAME WANT(0|1) REQ[@ALLOW] OUTFILE RC -> checks the verdict; for a FAIL, that some [FAIL]
# line matches REQ (the targeted check fired) and every [FAIL] line matches ALLOW (default REQ:
# nothing else fired, except the listed checks that a defect of this kind must also trip).
grade(){
  local name=$1 want=$2 re=${3%%@*} allow=${3#*@} out=$4 got=$5 stray
  if [ "$got" -ne "$want" ]; then
    echo "  [FAIL]  $name: expected $( [ "$want" -eq 0 ] && echo PASS || echo FAIL), got rc=$got"; sfail=1
    grep -E '\[FAIL\]' "$out" | head -4 | sed 's/^/          | /'; return
  fi
  if [ "$want" -eq 1 ]; then
    if ! grep -qE -- "$re" <<<"$(grep -E '\[FAIL\]' "$out")"; then
      echo "  [FAIL]  $name: rejected, but not by the targeted check (/$re/)"; sfail=1
      grep -E '\[FAIL\]' "$out" | head -4 | sed 's/^/          | /'; return
    fi
    stray=$(grep -E '\[FAIL\]' "$out" | grep -vE -- "$re|$allow" | head -1)
    if [ -n "$stray" ]; then
      echo "  [FAIL]  $name: another check also fired, so the leg is not isolated:"; sfail=1
      echo "          | $stray"; return
    fi
    echo "  [ok]    $name -> FAIL, by: $(grep -E '\[FAIL\]' "$out" | grep -E -- "$re" | head -1 | sed 's/^ *\[FAIL\] *//')"
  else
    echo "  [ok]    $name -> PASS"
  fi
}

# agg NAME WANT DIAG DOC LOG RUN13 [LOG_SHA TABLE_SHA TERMINAL]
agg(){
  local name=$1 want=$2 re=$3; shift 3
  aggregates "$@" >"$SD/$name.out" 2>&1
  grade "$name" "$want" "$re" "$SD/$name.out" $?
}
# agg_iso NAME DIAG DOC LOG RUN13 [TERMINAL] -> the same, with both digest pins set to the planted
# files' own digests, so only the targeted check can fire.
agg_iso(){
  local name=$1 re=$2 d=$3 l=$4 r=${5:-} term=${6:-$TERMINAL}
  agg "$name" 1 "$re" "$d" "$l" "$r" "$(sha "$l")" "$(tsha "$d")" "$term"
}
seded(){  # SRC DEST SED_EXPR NAME -> DEST = sed(SRC), and the plant must land
  sed -E "$3" "$1" > "$2"; landed "$1" "$2" "$4"
}

# A synthetic n=13 engine log in the engine's own record format, from section 2's n=13 column.
python3 - "$DOC" > "$SD/run13.log" <<'PY'
import math, sys
col, sec = {}, False
for l in open(sys.argv[1], encoding="utf-8"):
    if l.startswith("## "):
        sec = l.startswith("## 2."); continue
    if sec and l.startswith("|"):
        c = [x.strip().replace(",", "") for x in l.strip().strip("|").split("|")]
        if len(c) > 4 and c[3].isdigit() and c[4].isdigit():
            col.setdefault(int(c[3]), int(c[4]))
P = "[3,7,11,5,8,26,31,10,15,20,23,27,29]"
print("[f1c5] run: SUBSET n=13 pairs %s start_exit=0 n_eff=24 threads=1 layers_dir=out13" % P)
for k in sorted(col):
    print("[f1c5] layer k=%2d/13: canonical_masks=0 (of C(13,%d)=%d) states=0 entries=0 V_k=0 "
          "bytes=0.000000GB two_layer=0.000000GB peak2=0.000000GB mass=%d elapsed=0.00s total=0.0s"
          % (k, k, math.comb(13, k), col[k]))
print("F1C5 SUBSET n=13 pairs %s start_exit=0 B0=(1,6,0,6,0)" % P)
print("  orbit-quotient C5-DP total = %d" % col.get(13, 0))
PY
R13="$SD/run13.log"

echo "-- the aggregate check (step 13)"
agg control-real-inputs 0 x "$DOC" "$LOG" "$R13"
# The two digests, each alone.
agg table-digest-pin-wrong 1 'table digest' "$DOC" "$LOG" "" "$RUNOUT_SHA" "$(printf '0%.0s' {1..64})"
cp "$LOG" "$SD/run_flip.out"; printf 'X' | dd of="$SD/run_flip.out" bs=1 seek=100 conv=notrunc status=none
landed "$LOG" "$SD/run_flip.out" log-flip && agg log-one-byte-flipped 1 "run log's sha256" "$DOC" "$SD/run_flip.out" ""
# The field comparison, with both digests re-pinned to the planted files.
seded "$DOC" "$SD/doc_mass.md" 's/^(\| 12 \|.*\| )69,297,073,054,612,254,336 \|$/\169,297,073,054,612,254,337 |/' doc-mass && \
  agg_iso table-mass-plus-one 'k=12 mass:@all 7 columns' "$SD/doc_mass.md" "$LOG"
seded "$DOC" "$SD/doc_states.md" 's/^(\| 5 \| 9,707 \| 169,911 \| )97,070 /\197,071 /' doc-states && \
  agg_iso table-states-cell 'k=5 states:@all 7 columns' "$SD/doc_states.md" "$LOG"
seded "$LOG" "$SD/run_gb.out" 's/^(\[f1c5\] layer k= 9\/31: .* bytes=)([0-9.]+)GB/\19.999999GB/' log-gb && \
  agg_iso log-layer-GB-cell 'k=9 layer GB:@all 7 columns' "$DOC" "$SD/run_gb.out"
# C(31,k) by arithmetic: the same wrong cell in table AND log, so the comparison agrees.
seded "$DOC" "$SD/doc_c.md" 's/^(\| 3 \| [0-9,]+ \| )4,495 \|/\14,496 |/' doc-comb && \
seded "$LOG" "$SD/run_c.out" 's/^(\[f1c5\] layer k= 3\/31: canonical_masks=[0-9]+ \(of C\(31,3\)=)4495\)/\14496)/' log-comb && \
  { agg_iso comb-cell-in-both-table "table's C\\(31,k\\) cell@run log's C\\(31,k\\)" "$SD/doc_c.md" "$SD/run_c.out"
    agg_iso comb-cell-in-both-log "run log's C\\(31,k\\) field@table's C\\(31,k\\)" "$SD/doc_c.md" "$SD/run_c.out"; }
# The terminal anchor: k=31 moved by 24 (still divisible) in the table and the log's k=31 layer
# record, but not in the log's final-count lines (those have their own leg below).
NEWT=1097051278789181790036112071176579186712
seded "$DOC" "$SD/doc_term.md" "s/1,097,051,278,789,181,790,036,112,071,176,579,186,688 \|\$/1,097,051,278,789,181,790,036,112,071,176,579,186,712 |/" doc-terminal && \
seded "$LOG" "$SD/run_term.out" "/^\\[f1c5\\] layer k=31\\/31:/s/$TERMINAL/$NEWT/" log-terminal && \
  agg_iso terminal-moved-in-table-and-layer 'published total' "$SD/doc_term.md" "$SD/run_term.out"
# Divisibility alone: k=31 moved by ONE everywhere and the terminal pin moved with it.
NEW1=1097051278789181790036112071176579186689
seded "$DOC" "$SD/doc_div.md" "s/1,097,051,278,789,181,790,036,112,071,176,579,186,688 \|\$/1,097,051,278,789,181,790,036,112,071,176,579,186,689 |/" doc-div && \
seded "$LOG" "$SD/run_div.out" "s/$TERMINAL/$NEW1/g" log-div && \
  agg_iso total-not-divisible-by-24 'divisible by 24' "$SD/doc_div.md" "$SD/run_div.out" "" "$NEW1"
# Record-level checks of the full-31 log (Codex PKG-V1 finding 3).
python3 - "$LOG" "$SD/run_dup.out" "$SD/run_lab.out" "$SD/run_fin.out" "$SD/run_sess.out" <<'PY'
import re, sys
src = open(sys.argv[1], encoding="utf-8").read().split("\n")
i7 = next(i for i, l in enumerate(src) if l.startswith("[f1c5] layer k= 7/31:"))
wrong = re.sub(r" mass=(\d+) ", lambda m: " mass=%d " % (int(m.group(1)) + 1), src[i7])
open(sys.argv[2], "w").write("\n".join(src[:i7] + [wrong] + src[i7:]))            # wrong k=7 first
open(sys.argv[3], "w").write("\n".join(l.replace("/31:", "/13:", 1) if l.startswith("[f1c5] layer k= 4/31:") else l for l in src))
fin = max(i for i, l in enumerate(src) if l.startswith("F1C5 EXACT |"))
open(sys.argv[4], "w").write("\n".join(src[:fin + 1] + ["F1C5 EXACT |C1 & C2 & C4 & C5| = 1"] + src[fin + 1:]))
ses = next(i for i, l in enumerate(src) if l.startswith("[f1c5] run: FULL-31"))
open(sys.argv[5], "w").write("\n".join(src[:ses] + [src[ses].replace("FULL-31 n=31", "SUBSET n=13", 1)] + src[ses + 1:]))
PY
landed "$LOG" "$SD/run_dup.out" log-dup && \
  agg_iso log-layer-repeated-wrong-first 'appears twice@k=7 mass|all 7 columns' "$DOC" "$SD/run_dup.out"
landed "$LOG" "$SD/run_lab.out" log-label && \
  agg_iso log-layer-relabelled-13 'well-formed full-31@layer record for each k|all 7 columns' "$DOC" "$SD/run_lab.out"
landed "$LOG" "$SD/run_fin.out" log-final && \
  agg_iso log-second-final-count-1 'final-count line' "$DOC" "$SD/run_fin.out"
landed "$LOG" "$SD/run_sess.out" log-session && \
  agg_iso log-session-other-problem 'full-31 problem' "$DOC" "$SD/run_sess.out"
# A full-31 session line with the right name but another starting exit (Codex PKG-V3 finding 7).
seded "$LOG" "$SD/run_sess63.out" '0,/^(\[f1c5\] run: FULL-31 n=31 pairs \[[0-9,]+\] start_exit=)0 /s//\163 /' log-session-exit && \
  agg_iso log-session-other-start 'full-31 problem' "$DOC" "$SD/run_sess63.out"

echo "-- your n=13 log (step 13, second half)"
python3 - "$R13" "$SD" <<'PY'
import os, re, sys
src = open(sys.argv[1]).read().split("\n"); d = sys.argv[2]
def w(name, lines): open(os.path.join(d, name), "w").write("\n".join(lines))
i7 = next(i for i, l in enumerate(src) if l.startswith("[f1c5] layer k= 7/13:"))
w("r13_plus1.log", [l.replace(" mass=227208960 ", " mass=227208961 ") for l in src])
w("r13_dup.log", src[:i7] + [src[i7].replace(" mass=227208960 ", " mass=227208961 ")] + src[i7:])
tot = next(i for i, l in enumerate(src) if "orbit-quotient C5-DP total" in l)
w("r13_tot.log", src[:tot + 1] + ["  orbit-quotient C5-DP total = 1"] + src[tot + 1:])
w("r13_lab.log", [l.replace("/13:", "/31:", 1) if l.startswith("[f1c5] layer k= 5/13:") else l for l in src])
w("r13_comb.log", [l.replace("(of C(13,6)=1716)", "(of C(13,6)=1717)") for l in src])
w("r13_tworuns.log", src + src)
w("r13_wrongtot.log", [l.replace("total = 2063395607040", "total = 2063395607041") for l in src])
w("r13_order.log", [src[tot]] + src[:tot] + src[tot + 1:])
P13 = "[3,7,11,5,8,26,31,10,15,20,23,27,29]"
w("r13_pairs.log", [l.replace(P13, "[1,2,3,4,5,6,7,8,9,10,11,12,13]") for l in src])
i3 = next(i for i, l in enumerate(src) if l.startswith("[f1c5] layer k= 3/13:"))
w("r13_swap.log", src[:i3] + [src[i3 + 1], src[i3]] + src[i3 + 2:])
PY
for f in r13_plus1 r13_dup r13_tot r13_lab r13_comb r13_tworuns r13_wrongtot r13_order r13_pairs r13_swap; do landed "$R13" "$SD/$f.log" "$f" || true; done
agg n13-layer-plus-one     1 'n=13 engine masses'                               "$DOC" "$LOG" "$SD/r13_plus1.log"
agg n13-layer-repeated     1 'appears twice@n=13 engine masses'                 "$DOC" "$LOG" "$SD/r13_dup.log"
agg n13-second-total-1     1 'exactly one n=13 run@n=13 total'                   "$DOC" "$LOG" "$SD/r13_tot.log"
agg n13-layer-labelled-31  1 'well-formed n=13@record for k = 1..13|n=13 engine masses' "$DOC" "$LOG" "$SD/r13_lab.log"
agg n13-wrong-C13k         1 'well-formed n=13@record for k = 1..13|n=13 engine masses' "$DOC" "$LOG" "$SD/r13_comb.log"
agg n13-two-runs-in-a-log  1 'exactly one n=13 run@appears twice|n=13 total|run order' "$DOC" "$LOG" "$SD/r13_tworuns.log"
agg n13-wrong-total        1 'n=13 total'                                       "$DOC" "$LOG" "$SD/r13_wrongtot.log"
agg n13-total-before-run   1 'run order'                                        "$DOC" "$LOG" "$SD/r13_order.log"
agg n13-other-pair-list    1 'exactly one n=13 run'                             "$DOC" "$LOG" "$SD/r13_pairs.log"
agg n13-layers-3-4-swapped 1 'run order'                                        "$DOC" "$LOG" "$SD/r13_swap.log"
# Section 2's n=13 column with a second, wrong row for k=1 after the right one (finding 5).
seded "$DOC" "$SD/doc_s2dup.md" 's/^(\| 1 \| 12 \| \| 1 \| 6 \| \| 1 \| 32 \|)$/\1\n| 1 | 999 | | 1 | 999 | | 1 | 999 |/' doc-s2dup && \
  agg n13-column-repeated-row 1 'one well-formed n=13 mass' "$SD/doc_s2dup.md" "$LOG" "$R13"

echo "-- the manifest (before step 1)"
MP="$SD/pkg"
populate "$MP" "$ROOT" "${PKG_FILES[@]}" >/dev/null || sfail=1
printf 'ROAE reviewer package selftest fixture\n' > "$MP/reviewer/PACKAGE_VERSION"
mkmanifest(){ (cd "$MP" && printf '%s\n' "${PKG_FILES[@]}" reviewer/PACKAGE_VERSION | LC_ALL=C sort | xargs sha256sum) > "$MP/reviewer/MANIFEST.sha256"; }
man(){  # NAME WANT DIAG
  check_manifest "$MP" >"$SD/$1.out" 2>&1; grade "$1" "$2" "$3" "$SD/$1.out" $?
}
mkmanifest; man manifest-control 0 x
cp "$MP/solve.c" "$SD/solve.c.orig"; printf '\n' >> "$MP/solve.c"; man manifest-file-changed 1 'solve.c differs'
cp "$SD/solve.c.orig" "$MP/solve.c"; man manifest-file-restored 0 x
grep ' LICENSE.md$' "$MP/reviewer/MANIFEST.sha256" > "$SD/m1"; cp "$SD/m1" "$MP/reviewer/MANIFEST.sha256"
man manifest-truncated 1 'does not list'
mkmanifest; tail -1 "$MP/reviewer/MANIFEST.sha256" >> "$MP/reviewer/MANIFEST.sha256"; man manifest-duplicate-line 1 'more than once'
mkmanifest; printf '%s  out13/f1c5_layer_00.bin\n' "$(printf '0%.0s' {1..64})" >> "$MP/reviewer/MANIFEST.sha256"
man manifest-extra-entry 1 'not a package file'
rm -f -- "$MP/reviewer/MANIFEST.sha256"; man manifest-removed 1 'no readable reviewer/MANIFEST'
# Both marker files removed and a source file changed (Codex PKG-V3 finding 8): still a FAIL,
# unless the reader says --source-checkout.
mv "$MP/reviewer/PACKAGE_VERSION" "$SD/pv.saved"; printf '\n' >> "$MP/solve.c"
man manifest-both-markers-removed 1 'not an intact package'
check_manifest "$MP" 1 >"$SD/manifest-source-checkout.out" 2>&1; rc=$?
if [ "$rc" -eq 0 ] && grep -qx 'PACKAGE_MANIFEST=SKIPPED' "$SD/manifest-source-checkout.out"; then
  echo "  [ok]    manifest-source-checkout -> SKIPPED (only with --source-checkout)"
else
  echo "  [FAIL]  manifest-source-checkout: expected PACKAGE_MANIFEST=SKIPPED, rc 0 (got rc=$rc)"; sfail=1
fi
cp "$SD/solve.c.orig" "$MP/solve.c"; mv "$SD/pv.saved" "$MP/reviewer/PACKAGE_VERSION"
mkmanifest

echo "-- verdicts: the checker's exit status AND exactly one verdict line (Q-951 / Q-952 class)"
# A stand-in python3 for the aggregate and manifest checkers: a verdict line beside a crash, no
# verdict, two verdicts, or a verdict that disagrees with the exit status must be ERROR (rc 2).
VS="$SD/vshim"
vleg(){  # NAME KEY BODY -> run the checker for KEY with a stand-in python3 running BODY
  local name=$1 key=$2 body=$3 out rc
  stub "$VS/$name/python3" "cat >/dev/null; $body"
  if [ "$key" = AGGREGATES ]; then out=$(PATH="$VS/$name:$PATH" aggregates "$DOC" "$LOG" "" 2>&1); rc=$?
  else out=$(PATH="$VS/$name:$PATH" check_manifest "$MP" 2>&1); rc=$?; fi
  if [ "$rc" -eq 2 ] && [ "$(grep -c "^$key=" <<<"$out")" -eq 1 ] && grep -qx "$key=ERROR" <<<"$out" \
     && grep -q '\[ERROR\] .*did not finish cleanly' <<<"$out"; then
    echo "  [ok]    $name -> $key=ERROR (rc 2)"
  else
    echo "  [FAIL]  $name: expected one $key=ERROR line and rc 2, got rc=$rc:"; sfail=1
    grep -E "^$key=|\[(ERROR|FAIL)\]" <<<"$out" | head -3 | sed 's/^/          | /'
  fi
}
vleg agg-pass-then-killed   AGGREGATES 'echo AGGREGATES=PASS; exit 137'
vleg agg-no-verdict-rc0     AGGREGATES 'exit 0'
vleg agg-two-verdicts       AGGREGATES 'echo AGGREGATES=PASS; echo AGGREGATES=PASS; exit 0'
vleg agg-pass-then-fail     AGGREGATES 'echo AGGREGATES=PASS; echo AGGREGATES=FAIL; exit 1'
vleg agg-pass-rc1           AGGREGATES 'echo AGGREGATES=PASS; exit 1'
vleg agg-crash-rc1          AGGREGATES 'echo "Traceback (most recent call last):"; exit 1'
vleg manifest-ok-then-timeout PACKAGE_MANIFEST 'echo PACKAGE_MANIFEST=OK; exit 124'
vleg manifest-ok-rc1        PACKAGE_MANIFEST 'echo PACKAGE_MANIFEST=OK; exit 1'

echo "-- the runner: pass rule"
# mkpage NSTATED BODY NAME -> a page with the given steps
mkpage(){ printf '# t\n\nThere are **%s steps**.\n\n## The steps\n\n```text\n%s\n```\n' "$1" "$2" > "$SD/$3.md"; }
# runner NAME WANT(PASS|FAIL|ERROR) DIAG_REGEX SRC [FILE...] -> runs a page, checks verdict and diagnostic
runner(){
  local name=$1 want=$2 re=$3 src=$4 got; shift 4
  ( SCRATCH=""; KEEP=0; TIMES=""
    if ! check_page "$SD/$name.md"; then echo "VERDICT=FAIL"; exit 0; fi
    run_steps "$SD/$name.md" "$src" "$@"
    [ -n "$SCRATCH" ] && [ -d "$SCRATCH" ] && rm -rf -- "$SCRATCH"
    if [ "$NUNFIN" -gt 0 ]; then echo "VERDICT=ERROR"
    elif [ "$NFAIL" -eq 0 ] && [ "$NSTEP" -gt 0 ]; then echo "VERDICT=PASS"
    else echo "VERDICT=FAIL"; fi ) > "$SD/$name.run" 2>&1
  got=$(sed -n 's/^VERDICT=//p' "$SD/$name.run" | tail -1)
  if [ "$got" != "$want" ]; then
    echo "  [FAIL]  runner $name: expected $want, got ${got:-nothing}"; sfail=1
    grep -E '\[(FAIL|ERROR|TIMEOUT|CRASH)\]' "$SD/$name.run" | head -3 | sed 's/^/          | /'; return
  fi
  if [ "$want" != PASS ] && ! grep -qE -- "$re" <<<"$(grep -E '\[(FAIL|ERROR|TIMEOUT|CRASH)\]' "$SD/$name.run")"; then
    echo "  [FAIL]  runner $name: rejected, but not for the targeted reason (/$re/)"; sfail=1
    grep -E '\[(FAIL|ERROR|TIMEOUT|CRASH)\]' "$SD/$name.run" | head -3 | sed 's/^/          | /'; return
  fi
  local stray; stray=$(grep -E '\[(FAIL|ERROR|TIMEOUT|CRASH)\]' "$SD/$name.run" | grep -vE -- "$re" | head -1)
  if [ "$want" != PASS ] && [ -n "$stray" ]; then
    echo "  [FAIL]  runner $name: another check also fired, so the leg is not isolated:"; sfail=1
    echo "          | $stray"; return
  fi
  echo "  [ok]    runner $name -> $got$( [ "$want" != PASS ] && printf ', by: %s' "$(grep -E '\[(FAIL|ERROR|TIMEOUT|CRASH)\]' "$SD/$name.run" | grep -E -- "$re" | head -1 | sed 's/^ *\[[A-Z]*\] *//')")"
}
E="$SD/empty"; mkdir -p "$E"
DIG=40387eed07b11319ba3943fca64ab94a7e19c6acfb56d2b42ce86e6ac0625c4e
mkpage 2 $'[1] echo STEP_ONE=ok\n    expect: STEP_ONE=ok\n[2] printf \'all 9 layer masses MATCH x  [0.0s]\\n\'\n    expect: all 9 layer masses MATCH …' p_ok
mkpage 2 $'[1] echo STEP_ONE=ok\n    expect: STEP_ONE=no\n[2] echo x\n    expect: x' p_expect
mkpage 1 $'[1] echo STEP_ONE=ok; exit 9\n    expect: STEP_ONE=ok' p_rc_all_tokens
mkpage 1 $'[1] { echo PIPE=ok; exit 3; } | tee out.txt\n    expect: PIPE=ok' p_pipe_producer_fails
mkpage 2 $'[1] echo STEP_ONE=ok\n    expect: STEP_ONE=ok\n[2] echo a\n    expect: a\n[3] echo extra\n    expect: extra' p_count
mkpage 1 $'[1] echo STEP_ONE=ok' p_noexp
mkpage 1 $'[1] echo STEP_ONE=ok_but_longer\n    expect: STEP_ONE=ok' p_wholeline
mkpage 1 $'[1] echo \'KC COUNT n=13 = 20633956070400\'\n    expect: KC COUNT n=13 = 2063395607040' p_extra_digit
mkpage 1 "[1] echo 'x${DIG}0  -'"$'\n'"    expect: ${DIG}  -" p_malformed_digest
mkpage 1 $'[1] echo "note: expected \'[--selftest] PASS — sha256 matches canonical baseline\'"\n    expect: [--selftest] PASS — sha256 matches canonical baseline' p_quoted_success
mkpage 1 $'[1] echo AGGREGATES=PASS; echo AGGREGATES=FAIL\n    expect: AGGREGATES=PASS' p_conflicting_verdict
mkpage 1 $'[1] echo \'all 9 layer masses MATCHED\'\n    expect: all 9 layer masses MATCH …' p_prefix_runs_on
mkpage 1 $'[1] echo \'note: all 9 layer masses MATCH\'\n    expect: all 9 layer masses MATCH …' p_prefix_not_at_start
# Contradicting lines beside a matched one (Codex PKG-V3 finding 4), and the control that another
# record of the same form with another label is not a contradiction.
mkpage 1 $'[1] printf \'layer  1: recount 12  published 12  [ok]\\nlayer  9: recount 26,112  published 26,112  [ok]\\n\'\n    expect: layer  9: recount 26,112  published 26,112  [ok]' p_same_form_other_label
mkpage 1 $'[1] printf \'KC COUNT n=13 = 2063395607040\\nKC COUNT n=13 = 1\\n\'\n    expect: KC COUNT n=13 = 2063395607040' p_same_form_other_value
mkpage 1 $'[1] printf \'all 9 layer masses MATCH x  [0.0s]\\n*FAIL* 1 of 9 layer(s) disagree\\n\'\n    expect: all 9 layer masses MATCH …' p_reports_failure
runner p_ok                  PASS x                          "$E"
runner p_expect              FAIL 'exactly: STEP_ONE=no'     "$E"
runner p_rc_all_tokens       FAIL 'exit status 9'            "$E"
runner p_pipe_producer_fails FAIL 'exit status 3'            "$E"
runner p_count               FAIL 'states 2 steps'           "$E"
runner p_noexp               FAIL 'no expect: line'          "$E"
runner p_wholeline           FAIL 'exactly: STEP_ONE=ok'     "$E"
runner p_extra_digit         FAIL 'exactly: KC COUNT'        "$E"
runner p_malformed_digest    FAIL "exactly: ${DIG}"          "$E"
runner p_quoted_success      FAIL 'exactly: \[--selftest\]'  "$E"
runner p_conflicting_verdict FAIL 'conflicting verdict'      "$E"
runner p_prefix_runs_on      FAIL 'begins with'              "$E"
runner p_prefix_not_at_start FAIL 'begins with'              "$E"
runner p_same_form_other_label PASS x                        "$E"
runner p_same_form_other_value FAIL 'conflicting line'       "$E"
runner p_reports_failure     FAIL 'reports a failure'        "$E"
# A step that did not finish, a verdict printed twice, and a failure after an expected prefix
# (the Q-951 / Q-952 class, batch 39).
mkpage 1 $'[1] echo STEP_ONE=ok; sleep 5\n    expect: STEP_ONE=ok' p_timeout
mkpage 1 $'[1] echo STEP_ONE=ok; kill -SEGV $$\n    expect: STEP_ONE=ok' p_crash
mkpage 1 $'[1] { echo PIPE=ok; kill -KILL $BASHPID; } | tee out.txt\n    expect: PIPE=ok' p_crash_behind_tee
mkpage 1 $'[1] echo AGGREGATES=PASS; echo AGGREGATES=PASS\n    expect: AGGREGATES=PASS' p_verdict_twice
mkpage 1 $'[1] printf \'all 9 layer masses MATCH x  [0.0s] FAIL\\n\'\n    expect: all 9 layer masses MATCH …' p_prefix_then_fail
mkpage 1 $'[1] printf \'STEP_ONE=ok\\nERROR: layer 3 unreadable\\n\'\n    expect: STEP_ONE=ok' p_reports_error
mkpage 1 $'[1] printf \'STEP_ONE=ok\\nTraceback (most recent call last):\\n\'\n    expect: STEP_ONE=ok' p_traceback
SELFCHECK_STEP_TIMEOUT=1 runner p_timeout ERROR '\[TIMEOUT\]' "$E"
runner p_crash               ERROR '\[CRASH\] .*signal 11'  "$E"
runner p_crash_behind_tee    ERROR '\[CRASH\] .*signal 9'   "$E"
runner p_verdict_twice       FAIL 'exactly once'             "$E"
runner p_prefix_then_fail    FAIL 'reports a failure'        "$E"
runner p_reports_error       FAIL 'reports a failure'        "$E"
runner p_traceback           FAIL 'reports a failure'        "$E"

echo "-- the runner: isolation (Codex PKG-V1 finding 1)"
# A package directory that already holds a reader's outputs. The step must not see them, and
# nothing it writes, including through same-named files, may reach the package directory.
IP="$SD/iso_pkg"; mkdir -p "$IP/out13"
printf 'input\n' > "$IP/in.txt"; printf 'stale\n' > "$IP/out13/f1c5_layer_00.bin"; printf 'ORIGINAL\n' > "$IP/run13.log"
(cd "$IP" && find . -type f -exec sha256sum {} + | LC_ALL=C sort) > "$SD/iso_before"
mkpage 1 $'[1] test ! -e out13 && test ! -e run13.log && echo new > run13.log && mkdir out13 && echo x >> in.txt && echo ISOLATED=yes\n    expect: ISOLATED=yes' p_isolated
runner p_isolated PASS x "$IP" in.txt
(cd "$IP" && find . -type f -exec sha256sum {} + | LC_ALL=C sort) > "$SD/iso_after"
if cmp -s "$SD/iso_before" "$SD/iso_after"; then
  echo "  [ok]    the package directory is byte-for-byte unchanged after the step"
else
  echo "  [FAIL]  the step changed the package directory:"; diff "$SD/iso_before" "$SD/iso_after" | head -4 | sed 's/^/          | /'; sfail=1
fi
# The real package list: a scratch made from this package holds exactly PKG_FILES, so a reader's
# own out13/, kc13/, run13.log, solve or verify in the package directory is never copied in.
RS="$SD/real_scratch"; mkdir -p "$RS"
populate "$RS" "$ROOT" "${PKG_FILES[@]}" >/dev/null || sfail=1
if [ "$( (cd "$RS" && find . -type f | sed 's#^\./##' | LC_ALL=C sort) )" = "$(printf '%s\n' "${PKG_FILES[@]}" | LC_ALL=C sort)" ]; then
  echo "  [ok]    a scratch made from this package holds exactly its ${#PKG_FILES[@]} input files"
else
  echo "  [FAIL]  a scratch made from this package does not hold exactly PKG_FILES"; sfail=1
fi

echo "-- the real page's steps, against stand-in programs"
# Each leg takes ONE real step (its command and its expect: lines, read from the page) and runs it
# in a fixture whose programs are small stand-in scripts: first a control whose stand-ins print what
# a correct run prints (must PASS), then a stand-in with one planted defect (must FAIL, for the
# planted reason). This shows the real page's expectations can fail, without a compiler.
check_page "$README" >/dev/null 2>&1 || { echo "  [FAIL]  the real page does not parse"; sfail=1; }
REAL_TSV=$STEPS_TSV
real_step_page(){  # STEPNO NAME -> $SD/NAME.md holding that one real step
  local c; c=$(awk -F'\t' -v n="$1" '$1=="STEP" && $2==n{print $3}' <<<"$REAL_TSV")
  { printf '# t\n\nThere are **1 steps**.\n\n## The steps\n\n```text\n[1] %s\n' "$c"
    awk -F'\t' -v n="$1" '$1=="EXPECT" && $2==n{printf "    expect: %s\n", $3}' <<<"$REAL_TSV"
    printf '```\n'; } > "$SD/$2.md"
}
stepno(){ awk -F'\t' -v p="$1" '$1=="STEP" && index($3, p){print $2; exit}' <<<"$REAL_TSV"; }
S_SELF=$(stepno './solve --selftest'); S_ENG=$(stepno '--f1-exact-c1c2c4c5'); S_KC=$(stepno '--kc-count')
S_KCB=$(stepno '--kc-build')
if [ -z "$S_SELF" ] || [ -z "$S_ENG" ] || [ -z "$S_KC" ] || [ -z "$S_KCB" ]; then
  echo "  [FAIL]  could not find the selftest, engine and catalog-query steps on the page"; sfail=1
else
  # (a) the engine regression check: the right PASS line beside a wrong sha.
  F="$SD/st_self"; real_step_page "$S_SELF" st_self_ok; cp "$SD/st_self_ok.md" "$SD/st_self_bad.md"
  stub "$F/ok/solve" 'echo "[--selftest] Actual sha256:   403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e"; echo "[--selftest] PASS — sha256 matches canonical baseline"'
  stub "$F/bad/solve" 'echo "[--selftest] Actual sha256:   403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332f"; echo "[--selftest] PASS — sha256 matches canonical baseline"'
  runner st_self_ok  PASS x                           "$F/ok"  solve
  runner st_self_bad FAIL 'exactly: \[--selftest\] Actual' "$F/bad" solve
  # ... the right lines, then a second, all-zero sha; or then the engine's own failure line.
  cp "$SD/st_self_ok.md" "$SD/st_self_zero.md"; cp "$SD/st_self_ok.md" "$SD/st_self_failline.md"
  stub "$F/zero/solve" 'echo "[--selftest] Actual sha256:   403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e"; echo "[--selftest] PASS — sha256 matches canonical baseline"; echo "[--selftest] Actual sha256:   0000000000000000000000000000000000000000000000000000000000000000"'
  stub "$F/failline/solve" 'echo "[--selftest] Actual sha256:   403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e"; echo "[--selftest] PASS — sha256 matches canonical baseline"; echo "[--selftest] FAIL — sha mismatch!"'
  runner st_self_zero     FAIL 'conflicting line'  "$F/zero"     solve
  runner st_self_failline FAIL 'reports a failure' "$F/failline" solve
  # (a2) the catalog build: the right line, then a second one with another count.
  F="$SD/st_kcb"; real_step_page "$S_KCB" st_kcb_ok; cp "$SD/st_kcb_ok.md" "$SD/st_kcb_two.md"
  stub "$F/ok/solve"  'echo "KC BUILD n=13 dir=kc13 count=2063395607040 layers=1.141276 MB elapsed=0.379s"'
  stub "$F/two/solve" 'echo "KC BUILD n=13 dir=kc13 count=2063395607040 layers=1.141276 MB elapsed=0.379s"; echo "KC BUILD n=13 dir=kc13 count=1 layers=1.141276 MB elapsed=0.379s"'
  runner st_kcb_ok  PASS x                  "$F/ok"  solve
  runner st_kcb_two FAIL 'conflicting line' "$F/two" solve
  # (b) the engine run: both expected lines printed, then a nonzero exit hidden behind `| tee`.
  F="$SD/st_eng"; real_step_page "$S_ENG" st_eng_ok; cp "$SD/st_eng_ok.md" "$SD/st_eng_rc.md"
  ENG_OUT=$(awk -F'\t' -v n="$S_ENG" '$1=="EXPECT" && $2==n{printf "echo %c%s%c; ", 39, $3, 39}' <<<"$REAL_TSV")
  stub "$F/ok/solve" "${ENG_OUT} exit 0"
  stub "$F/rc/solve" "${ENG_OUT} exit 9"
  runner st_eng_ok PASS x               "$F/ok" solve
  runner st_eng_rc FAIL 'exit status 9' "$F/rc" solve
  # (c) the catalog query: the count, and the catalog's own layer files. The control's stand-in
  # sha256sum prints the published digest; the corrupt-catalog leg uses the real sha256sum on
  # catalog files that are not the published bytes, with the count still right (Codex PKG-V1
  # finding 4); the count leg prints ten times the count (finding 2).
  F="$SD/st_kc"; for v in ok corrupt count two; do
    mkdir -p "$F/$v/kc13"; printf 'not the published bytes\n' > "$F/$v/kc13/f1c5_layer_07.bin"
    printf 'layer 0\n' > "$F/$v/kc13/f1c5_layer_00.bin"
    real_step_page "$S_KC" "st_kc_$v"
  done
  stub "$F/ok/solve"      'echo "KC COUNT n=13 = 2063395607040"'
  stub "$F/corrupt/solve" 'echo "KC COUNT n=13 = 2063395607040"'
  stub "$F/count/solve"   'echo "KC COUNT n=13 = 20633956070400"'
  stub "$F/two/solve"     'echo "KC COUNT n=13 = 2063395607040"; echo "KC COUNT n=13 = 1"'
  stub "$F/stubbin/sha256sum" "if [ \$# -eq 0 ]; then cat >/dev/null; echo '${DIG}  -'; else for f in \"\$@\"; do echo \"0000  \$f\"; done; fi"
  KCF=(solve kc13/f1c5_layer_00.bin kc13/f1c5_layer_07.bin)
  SAVED_PATH=$PATH; PATH="$F/stubbin:$PATH"
  runner st_kc_ok    PASS x                   "$F/ok"    "${KCF[@]}"
  runner st_kc_count FAIL 'exactly: KC COUNT' "$F/count" "${KCF[@]}"
  runner st_kc_two   FAIL 'conflicting line'  "$F/two"   "${KCF[@]}"
  PATH=$SAVED_PATH
  runner st_kc_corrupt FAIL "exactly: ${DIG}" "$F/corrupt" "${KCF[@]}"
fi

echo "-- the real page"
if check_page "$README" >"$SD/page.out" 2>&1; then
  echo "  [ok]    the real page: $(awk -F'\t' '/^STATED/{print $2}' <<<"$STEPS_TSV") steps, numbered and checked"
else
  echo "  [FAIL]  the real page does not parse:"; sed 's/^/          | /' "$SD/page.out"; sfail=1
fi

if [ "$sfail" -eq 0 ]; then echo "SELFCHECK_SELFTEST=PASS"; exit 0; fi
echo "SELFCHECK_SELFTEST=FAIL"; exit 1
