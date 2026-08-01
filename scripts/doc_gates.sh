#!/usr/bin/env bash
# doc_gates.sh — mechanical documentation-integrity gates.
#
# WHY THIS EXISTS
#   The code layer has hard gates (canonical sha, compile gate, tests.py, DRAT certs).
#   The DOC layer had none, so doc-level defects depended on review luck. On 2026-08-01
#   two full adversarial AI review passes cleared the repo and a third found ~20 real
#   defects — including a retracted claim still stated on the README front page, hidden
#   because a revision entry *asserted* the correction had propagated. These gates turn
#   that class of failure from "hope a reviewer notices" into "the script fails".
#
# USAGE
#   scripts/doc_gates.sh numbers    # cross-file numeric consistency (long integers)
#   scripts/doc_gates.sh cli        # CLI flags live in code but absent from the CLI docs
#   scripts/doc_gates.sh retract    # retracted phrasings that still survive in the corpus
#   scripts/doc_gates.sh links      # internal markdown links + #anchors that do not resolve
#   scripts/doc_gates.sh status     # canonical quantities whose exact/estimate status drifted
#   scripts/doc_gates.sh figures    # retracted phrasing in figure GENERATORS (rendered text is ungreppable)
#   scripts/doc_gates.sh all        # run all six
#
# EXIT: 0 = clean, 1 = findings. Report-only classes print [WARN]; hard failures print [FAIL].
#
# SAFETY: index-based (`git ls-files`/`git grep`) and fixed-string matching only.
#   No `find` over trees, no bounded-repetition regex (`.{0,N}`) — a pathological
#   `grep -oE ".{0,80}X.{0,60}"` hung the 2-core orchestrator on a 381-byte input
#   (2026-08-01); cost lives in the PATTERN, not only the data.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
RC=0

# example/ was excluded here until 2026-08-01. That is a CONTAINER-level exemption — the same
# construction that let the retracted "hard floor k >= 13" survive in TR-4's body while its
# changelog narrated the retraction. Exempt a construction, never a directory.
DOCS=$(git ls-files '*.md' || true)

# ----------------------------------------------------------------------------------
gate_numbers() {
  echo "== GATE 1: cross-file numeric consistency (long integers) =="
  # Extract integers of >=12 digits (commas stripped). Group by their first 10 digits.
  # A group holding more than one DISTINCT full value means two docs disagree about
  # what is almost certainly the same quantity (e.g. a single corrupted digit).
  # Key = (length, first 10 digits). SAME LENGTH matters: a corrupted digit preserves
  # length, whereas 10^11 vs 10^12 are simply different budgets, not a disagreement.
  # Round numbers (>=4 trailing zeros) are budgets/powers of ten — skipped.
  # Report-only ([WARN]) with an allowlist, because legitimately-close pairs exist
  # (e.g. a byte count with and without the 32-byte header).
  local tmp allow; tmp=$(mktemp)
  allow="documentation/DOC_GATE_NUMBER_ALLOWLIST.txt"
  for f in $DOCS; do
    grep -oE '[0-9][0-9,]{11,}' "$f" 2>/dev/null | tr -d ',' \
      | awk -v F="$f" 'length($0)>=12 && $0 !~ /0000$/ {print length($0)":"substr($0,1,10)"\t"$0"\t"F}'
  done | sort -u > "$tmp"

  local found=0
  while read -r key; do
    [ -z "$key" ] && continue
    if [ -f "$allow" ] && grep -qxF -- "$key" "$allow" 2>/dev/null; then continue; fi
    echo "  [WARN] near-twin long integers (same length, same 10-digit prefix) — key $key:"
    awk -v K="$key" -F'\t' '$1==K {print "      "$2"   <- "$3}' "$tmp" | sort -u
    found=1
  done < <(cut -f1,2 "$tmp" | sort -u | cut -f1 | uniq -d)

  if [ "$found" -eq 0 ]; then
    echo "  [ok] no long integer disagrees with a same-length near-twin elsewhere"
  else
    echo "  (report-only: confirm each pair is intentional, then add its key to $allow)"
  fi
  rm -f "$tmp"
  return 0   # report-only gate — never blocks
}

# ----------------------------------------------------------------------------------
gate_cli() {
  echo "== GATE 2: CLI flags live in code but undocumented =="
  local bad=0
  check_pair() { # $1=code file  $2=doc file  $3=extractor
    local code="$1" doc="$2" mode="$3" cf df miss
    [ -f "$code" ] && [ -f "$doc" ] || { echo "  [skip] $code / $doc"; return 0; }
    cf=$(mktemp); df=$(mktemp)
    if [ "$mode" = py ]; then
      grep -oE 'add_argument\("--[a-z0-9][a-z0-9_-]*' "$code" | sed 's/.*"//' | sort -u > "$cf"
    else
      grep -oE '"--[a-z0-9][a-z0-9-]*"' "$code" | tr -d '"' | sort -u > "$cf"
    fi
    grep -oE -- '--[a-z0-9][a-z0-9_-]*' "$doc" | sort -u > "$df"
    miss=$(comm -23 "$cf" "$df")
    if [ -n "$miss" ]; then
      echo "  [FAIL] in $code but NOT in $doc:"; echo "$miss" | sed 's/^/      /'; bad=1
    else
      echo "  [ok] $code fully documented in $doc"
    fi
    rm -f "$cf" "$df"
  }
  check_pair roae.py  documentation/ROAE_PY_CLI.md  py
  check_pair solve.py documentation/SOLVE_PY_CLI.md py
  check_pair solve.c  documentation/SOLVE_C_CLI.md  c
  # sat.py hand-rolls sys.argv parsing with literal quoted flag strings, so the
  # C-mode extractor applies verbatim (verified 2026-08-01: passes).
  check_pair sat.py   documentation/SAT_CLI.md      c
  return $bad
}

# ----------------------------------------------------------------------------------
gate_retract() {
  echo "== GATE 3: retracted phrasings still surviving =="
  # Registry-driven and deliberately so: auto-parsing retraction prose is unreliable,
  # and a wrong gate is worse than none. Each entry is a FIXED string that was retracted;
  # the gate fails if it appears anywhere outside the file allowed to narrate the retraction.
  #
  # HARDENED 2026-08-01 after this gate missed a LIVE survivor two ways at once
  # (SOLVE_SUMMARY.md still carried the retracted conflict-theorem scope):
  #   (a) line-break evasion — the phrase spanned a hard wrap, so line-based `git grep -F`
  #       could not see it. FIX: whitespace-normalise each file to a single line first.
  #   (b) morphology evasion — the registry held "preserving…" while the survivor said
  #       "preserves…". FIX: register the morphology-independent STEM (and add variants).
  #   (c) allow-column over-reach — matching the allow string anywhere on the line exempted
  #       too much. FIX: the allow column now matches the FILENAME only.
  local reg="documentation/RETRACTED_PHRASES.tsv"
  [ -f "$reg" ] || { echo "  [skip] no $reg"; return 0; }
  local bad=0
  while IFS=$'\t' read -r phrase allow note; do
    case "$phrase" in ''|'#'*) continue;; esac
    local np hits=""
    np=$(printf '%s' "$phrase" | tr '\n' ' ' | tr -s ' ')
    for f in $DOCS; do
      case "$f" in *"$allow"*) continue;; esac          # the doc allowed to narrate it
      # normalise the whole file to one whitespace-collapsed line, then fixed-string match
      if tr '\n' ' ' < "$f" | tr -s ' ' | grep -qF -- "$np"; then
        # changelog rows legitimately quote superseded wording; only exempt if EVERY
        # line-level hit is a revision row.
        if git grep -F -n -- "$np" -- "$f" 2>/dev/null | grep -qvE ':[0-9]+:\| v[0-9]'; then
          hits="$hits $f"
        elif ! git grep -qF -- "$np" -- "$f" 2>/dev/null; then
          hits="$hits $f(spans-lines)"                  # only visible after normalisation
        fi
      fi
    done
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing still present: \"$phrase\""
      echo "         ($note)"
      for h in $hits; do echo "      $h"; done
      bad=1
    else
      echo "  [ok] retracted: \"$phrase\""
    fi
  done < "$reg"
  return $bad
}

# ----------------------------------------------------------------------------------
gate_links() {
  echo "== GATE 4: internal markdown links + anchors resolve =="
  # Every [text](target) pointing INSIDE the repo must resolve: the file must exist,
  # and a #fragment must match a heading slug (GitHub rules, including the -1/-2
  # suffixing of duplicate headings) or an explicit <a name=>/<a id=> anchor.
  # External http(s)/mailto targets are NOT fetched — this gate is offline and
  # deterministic by design; link-rot is a separate, network-dependent concern.
  # A dangling CITATIONS.md#anchor is the specific failure this protects against:
  # attribution that silently stops resolving when a citation entry is renamed.
  python3 - <<'PY'
import os, re, sys, subprocess, collections
LINK = re.compile(r'\[[^\]]*\]\(([^)\s]+)\)')
HEAD = re.compile(r'^(#{1,6})\s+(.*?)\s*$', re.M)
def slug(t):
    t = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', t)
    t = re.sub(r'[`*_~]', '', t).strip().lower()
    t = re.sub(r'[^\w\s-]', '', t)
    return re.sub(r'\s+', '-', t)
mds = [p for p in subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True)
       .stdout.split()]
anchors = {}
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    seen, a = collections.Counter(), set()
    for _, h in HEAD.findall(txt):
        s = slug(h); seen[s] += 1
        a.add(s if seen[s] == 1 else f"{s}-{seen[s]-1}")
    a.update(re.findall(r'<a\s+(?:name|id)="([^"]+)"', txt))
    anchors[os.path.realpath(m)] = a
bad = []
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    base = os.path.dirname(m) or '.'
    for tgt in LINK.findall(txt):
        if tgt.startswith(('http://','https://','mailto:')):
            continue
        path, _, frag = tgt.partition('#')
        if path == '':
            dest = os.path.realpath(m)
        else:
            dest = os.path.realpath(os.path.join(base, path))
            if not os.path.exists(dest):
                bad.append((m, tgt, 'no such file')); continue
        if frag and dest in anchors and frag not in anchors[dest] \
           and frag.lower() not in anchors[dest]:
            bad.append((m, tgt, 'no such anchor'))
for m, t, why in bad:
    print(f"  [FAIL] {m} -> {t}  ({why})")
if not bad:
    print(f"  [ok] all internal links + anchors resolve across {len(mds)} markdown files")
sys.exit(1 if bad else 0)
PY
}

# ----------------------------------------------------------------------------------
gate_status() {
  echo "== GATE 5: canonical quantities keep their epistemic status =="
  # GATE 1 catches a number whose DIGITS changed. This catches the other half: a number
  # that keeps its digits while silently changing epistemic status — an estimate promoted
  # to "exact", or an exact count demoted to an estimate. reports/METHODS.md is the single
  # source of truth; documentation/CANONICAL_VALUE_STATUS.tsv is its machine-readable
  # projection. Report-only, because legitimate sentences DO compare the two (e.g. "the
  # ratio of the exact count to the Knuth estimate"), so an allowlist carries those.
  python3 - <<'PY'
import re, subprocess, sys, os
reg = 'documentation/CANONICAL_VALUE_STATUS.tsv'
allow = 'documentation/DOC_GATE_STATUS_ALLOWLIST.txt'
if not os.path.exists(reg):
    print(f"  [FAIL] missing registry {reg}"); sys.exit(1)
rows = []
for line in open(reg, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line.strip() or line.lstrip().startswith('#'): continue
    p = line.split('\t')
    if len(p) >= 2: rows.append((p[0].strip(), p[1].strip()))
allowed = set()
if os.path.exists(allow):
    allowed = {l.strip() for l in open(allow, encoding='utf-8')
               if l.strip() and not l.lstrip().startswith('#')}
EST = r'estimate|estimated|Knuth|\bCI\b|confidence|Monte'
EX  = r'\bexact|\bproven|\bproved'
files = [p for p in subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True)
         .stdout.split()]
seen = 0; bad = 0
for f in files:
    for ln, line in enumerate(open(f, encoding='utf-8', errors='replace').read().splitlines(), 1):
        for val, want in rows:
            if re.fullmatch(r'[\d.]+', val) and ',' not in val:
                if not re.search(re.escape(val) + r'\s*[×x]\s*10', line): continue
            elif val not in line:
                continue
            seen += 1
            he, hx = bool(re.search(EST, line, re.I)), bool(re.search(EX, line, re.I))
            conflict = (want == 'exact' and he and not hx) or (want == 'estimate' and hx and not he)
            if conflict:
                key = f"{f}:{ln}"
                if key in allowed: continue
                print(f"  [WARN] {f}:{ln} — {val[:28]} is '{want}' in METHODS but this line reads otherwise")
                print(f"         {line.strip()[:170]}")
                bad += 1
if bad == 0:
    print(f"  [ok] {seen} occurrences of {len(rows)} canonical quantities all carry a consistent status")
else:
    print(f"  (report-only: if a hit is a legitimate exact-vs-estimate COMPARISON, add its 'file:line' to {allow})")
sys.exit(0)
PY
}

# ----------------------------------------------------------------------------------
gate_figures() {
  echo "== GATE 6: figure GENERATORS carry no retracted phrasing =="
  # WHY: on 2026-08-01 a withdrawn claim ("hard floor k >= 13") was found RENDERED in a
  # published figure, having survived every gate. matplotlib converts text to glyph
  # paths, so fig_tr4_boundary_information.svg holds 0 <text> elements and 920 <use>
  # refs — the sentence is visible to a reader and invisible to grep. 38 of the repo's
  # 40 image assets are in that state (15 matplotlib SVGs incl. the PCA plots, plus
  # every PNG). We cannot grep the output, so we grep what PRODUCES it: the annotation
  # strings in the figure generators. Keeping generator text and figure in sync is the
  # generators' documented obligation.
  local reg="documentation/RETRACTED_PHRASES.tsv"
  [ -f "$reg" ] || { echo "  [skip] no $reg"; return 0; }
  local gens bad=0
  gens=$(git ls-files 'viz/*.py')
  [ -n "$gens" ] || { echo "  [skip] no figure generators tracked"; return 0; }
  while IFS=$'\t' read -r phrase allow note; do
    case "$phrase" in ''|'#'*) continue;; esac
    local np hits=""
    np=$(printf '%s' "$phrase" | tr '\n' ' ' | tr -s ' ')
    for f in $gens; do
      if tr '\n' ' ' < "$f" | tr -s ' ' | grep -qF -- "$np"; then hits="$hits $f"; fi
    done
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing in a figure generator: \"$phrase\""
      echo "         ($note)"
      for h in $hits; do echo "      $h  — regenerate the figure after fixing"; done
      bad=1
    fi
  done < "$reg"
  if [ "$bad" -eq 0 ]; then
    echo "  [ok] $(echo $gens | wc -w) figure generator(s) carry no registered retracted phrasing"
  fi
  return $bad
}

# ---------------------------------------------------------------------------
# GATE 7 — a run's status must not be frozen in the present tense, and a run
# must not be NAMED after a budget it never reached.
#
# Why: PASS1_TRAJECTORY_DETERMINISM.md — a doc CLAUDE.md lists under "Stable
# paper-citable findings" — described a run as "1000T (in flight)" and "3,666
# lines and growing" from 2026-04-24 until 2026-08-01. The run had stopped at
# ~154T on 2026-04-27. Worse, correcting the TENSE alone left the row labelled
# "Fresh 1000T": naming a run after a budget it never reached asserts the
# accomplishment just as strongly as the present tense did.
#
# HISTORY.md is exempt BY DESIGN. It is a dated narrative log; "the run is in
# flight as of this entry" is correct there and must not be rewritten. The
# whole point of that file is to preserve what was believed at the time.
gate_liveness() {
  echo "== GATE 7: no frozen present-tense run status; no run named after an unreached budget =="
  python3 - <<'PY'
import re, glob, sys
LIVE = ['in flight', 'currently running', 'results pending', 'and growing',
        'is underway', 'awaiting results', 'run is ongoing']
# Words that mean the status IS qualified rather than frozen, or that the text is
# quoting/correcting an old claim rather than making one.
# Each entry must describe an OUTCOME or mark the text as quoted/hypothetical.
# The first draft included 'budget', 'if ', 'would' and 'example' — far too generic.
# 'budget' alone made the gate VACUOUS on its own motivating example, because the
# stale table had a "Budget" column header three lines above the frozen status. A
# suppression list that matches ordinary prose suppresses everything; this is the
# same defect as a scrub that samples zero items and reports PASS.
DISPO = ['stopped at', 'was stopped', 'completed', 'requested', 'never reached',
         'never carried out', 'superseded', 'aborted', 'cancelled', 'partial',
         'previously read', 'corrected', 'no longer', 'observed scenario',
         'hypothetical', 'as of this', 'at the time']
bad = 0
# The registry is the authority on which budgets were actually REACHED. A run named
# after a budget in the registry is named correctly; one named after a budget that
# is NOT in the registry is asserting an accomplishment that may never have happened.
# Pattern-matching alone cannot tell those apart, and a gate that flags the correct
# ones too is a gate that gets ignored — the mistake GATE 4 of ops_gates.sh made.
reg = open('documentation/CANONICAL_HASHES.md', errors='replace').read()
REACHED = set(re.findall(r'\b([0-9.]+T)\b', reg))
files = [f for f in glob.glob('documentation/*.md') + glob.glob('reports/*.md') + ['README.md']
         if 'HISTORY.md' not in f]      # dated narrative is exempt by design
for f in files:
    text = open(f, errors='replace').read()
    lines = text.split('\n')
    for i, l in enumerate(lines, 1):
        low = l.lower()
        for k in LIVE:
            if k not in low:
                continue
            ctx = ' '.join(lines[max(0, i-4):i+3]).lower()
            if any(d in ctx for d in DISPO):
                continue
            print(f"  [FINDING] {f}:{i} — status frozen in the present tense: \"{k}\"")
            print(f"            {l.strip()[:110]}")
            bad = 1
            break
    for m in re.finditer(r'\b(\d+(?:\.\d+)?T) (run|campaign|enumeration)\b', text):
        if m.group(1) in REACHED:
            continue                      # budget was actually reached — correct name
        st = max(0, m.start() - 400)
        para = text[st:m.end() + 400].lower()
        if any(d in para for d in DISPO):
            continue                      # disposition is stated nearby
        ln = text[:m.start()].count('\n') + 1
        print(f"  [FINDING] {f}:{ln} — \"{m.group(0)}\" names a run after {m.group(1)}, which is")
        print(f"            not a budget any canonical reached, with no disposition nearby")
        bad = 1
if not bad:
    print("  [ok] no frozen run status; every budget-named run carries a disposition")
sys.exit(bad)
PY
}

case "${1:-all}" in
  numbers) gate_numbers || RC=1 ;;
  cli)     gate_cli     || RC=1 ;;
  retract) gate_retract || RC=1 ;;
  links)   gate_links   || RC=1 ;;
  status)  gate_status  || RC=1 ;;
  figures) gate_figures || RC=1 ;;
  liveness) gate_liveness || RC=1 ;;
  all)     gate_numbers || RC=1; echo; gate_cli || RC=1; echo; gate_retract || RC=1
           echo; gate_links || RC=1; echo; gate_status || RC=1
           echo; gate_figures || RC=1
           echo; gate_liveness || RC=1 ;;
  *) echo "usage: $0 {numbers|cli|retract|links|status|figures|liveness|all}"; exit 2 ;;
esac

echo
[ "$RC" -eq 0 ] && echo "DOC GATES: PASS" || echo "DOC GATES: FINDINGS (see above)"
exit $RC
