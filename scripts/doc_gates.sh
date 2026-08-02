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
#   scripts/doc_gates.sh retract    # GATE 3: retracted phrasings that still survive in the corpus
#   scripts/doc_gates.sh retract-figures  # GATE 3b: retracted FIGURES (statistics) restated with no
#                                   # supersession marker; content-anchored allowlist, no auto-exemption
#   scripts/doc_gates.sh links      # GATE 4 + 4b: internal markdown links/#anchors, then section refs
#   scripts/doc_gates.sh secrefs    # GATE 4b ALONE — plain-text `FILE.md §"..."` references (self-test target)
#   scripts/doc_gates.sh status     # GATE 5: canonical quantities whose exact/estimate status
#                                   # drifted, + GATE 5b: a canonical quantity restated with NO
#                                   # marker among siblings that carry one
#   scripts/doc_gates.sh figures    # retracted phrasing in figure GENERATORS (rendered text is ungreppable)
#   scripts/doc_gates.sh liveness   # frozen present-tense run status; runs named after unreached budgets
#   scripts/doc_gates.sh banner     # the TR banner is byte-identical across every report + index-aligned
#   scripts/doc_gates.sh appendonly # GATE 10a + 10b: CORRECTIONS.md has lost no committed line
#   scripts/doc_gates.sh appendonly-head    # GATE 10a ALONE — vs HEAD (self-test target)
#   scripts/doc_gates.sh appendonly-history # GATE 10b ALONE — vs every historical/published
#                                   # version, not just HEAD (self-test target)
#   scripts/doc_gates.sh ledger     # every RETRACTED_PHRASES.tsv row is recorded in CORRECTIONS.md
#   scripts/doc_gates.sh generated  # generated artifacts still match their generator (~135s, 3 runs; NOT in `all`)
#   scripts/doc_gates.sh all        # run all eleven cheap gates (1-7 incl. 3b, 9, 10, 11); `generated` is separate by cost
#   scripts/doc_gates.sh --selftest # mutation-test the gates themselves (requires a clean tree)
#
# EXIT: 0 = clean, 1 = findings. Report-only classes print [WARN]; hard failures print [FAIL].
# GATES 1 and 5 are REPORT-ONLY by construction — they always `return 0` / `sys.exit(0)`, so their
# findings never reach RC and are NOT covered by the "DOC GATES: PASS" banner. The banner says so.
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
        # RECORD WHERE, not just WHICH FILE (2026-08-02, #65). A bare filename makes the
        # reader re-run the search by hand to find out what the gate saw; with the registry
        # holding morphology-independent STEMS, the surviving sentence often does not read
        # like the registry row, so "which phrase matched" is a real question. Cite the first
        # line that is NOT a changelog row — the same line the condition below turns on.
        local hitln
        hitln=$(git grep -F -n -- "$np" -- "$f" 2>/dev/null | grep -vE ':[0-9]+:\| v[0-9]' \
                | head -1 | cut -d: -f2)
        if [ -n "$hitln" ]; then
          hits="$hits $f:$hitln"
        elif ! git grep -qF -- "$np" -- "$f" 2>/dev/null; then
          hits="$hits $f(spans-lines)"                  # only visible after normalisation
        fi
      fi
    done
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing still present: \"$phrase\""
      echo "         matched as the fixed string: \"$np\"   ($note)"
      for h in $hits; do echo "      $h"; done
      bad=1
    else
      echo "  [ok] retracted: \"$phrase\""
    fi
  done < "$reg"
  return $bad
}

# ----------------------------------------------------------------------------------
# GATE 3b — retracted FIGURES (2026-08-02, item A6). The half of the retraction surface
# GATE 3 and GATE 1 both miss.
#
# WHY. GATE 3 matches retracted PHRASES; GATE 1 only compares integers of >=12 digits.
# A retracted STATISTIC — "1.4σ", "~5,500×", "≈10×", "net +1.6" — is invisible to both.
# That is not hypothetical: the surviving "1.4σ above" in evidence/r11/PHASE2_README.md
# was found by a human reading (TR-2 v1.23), and TR-9's draft-stage note carried two
# figures its own v1.7 had superseded through five subsequent revisions (TR-9 v1.20).
# Both were one-off manual sweeps. This gate is that sweep, permanent.
#
# THE EXEMPTION PROBLEM, and why this gate has NO automatic exemption.
# A retracted figure is quoted MORE after its retraction than before — every revision row,
# every ledger entry, every "this sentence read X until <date>" note must repeat it to
# record what changed. GATE 3 handles that with a filename allow-column plus a changelog-row
# exemption. Neither works here, and the failure is measured, not assumed:
#   * filename is too coarse — the legitimate quotations sit in BODY paragraphs of files
#     (METHODS.md, CORRECTIONS.md, TR-9) that also carry live prose;
#   * a changelog exemption would have HIDDEN this gate's first live finding, TR-2 v1.12's
#     "2.0σ", which sits inside a revision row and had been superseded for a day.
# So every legitimate occurrence is an explicit, CONTENT-ANCHORED allowlist row, in the
# shape GATE 4b uses (A8's lesson: no line numbers — they drift). Anything not allowlisted
# is a [FAIL]. The cost is ~25 curated rows; the benefit is that the exemption mechanism
# cannot silently widen.
#
# WHY-IT-FIRED (#65): every finding prints the matched fixed string, the registry note
# saying what superseded it, and the line text. Every exemption prints its class and reason.
# Allowlist rows that no longer match anything are re-printed as [note] — the drift audit.
gate_retract_figures() {
  echo "== GATE 3b: retracted FIGURES restated without a supersession marker =="
  python3 - <<'PY'
import os, re, subprocess, sys
REG   = 'documentation/RETRACTED_FIGURES.tsv'
ALLOW = 'documentation/DOC_GATE_FIGURE_ALLOWLIST.txt'
if not os.path.exists(REG):
    print(f'  [skip] no {REG}'); sys.exit(0)

figs = []
for ln in open(REG, encoding='utf-8'):
    if not ln.strip() or ln.startswith('#'):
        continue
    f = ln.rstrip('\n').split('\t')
    if len(f) >= 2 and f[0].strip():
        figs.append((f[0], f[1]))

# (file, figure, anchor) -> (class, why).  Anchor is a fixed substring that must appear on
# the SAME LINE as the figure for the exemption to apply.
allow, used = {}, set()
if os.path.exists(ALLOW):
    for ln in open(ALLOW, encoding='utf-8'):
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.rstrip('\n').split('\t')
        if len(f) >= 5:
            allow[(f[0], f[1], f[2])] = (f[3], f[4])

mds = subprocess.run(['git', 'ls-files', '*.md'], capture_output=True, text=True).stdout.split()
# COST, evaluated before writing it (box-safety rule): |mds| ~ 130 files x ~500 lines x
# |figs| = 9 fixed-string `in` tests ~ 6e5 substring checks over data already in memory.
# No regex, no bounded repetition, no accumulation across the loop.
bad, exempt, spans = [], [], []
# The registry (.tsv) and the allowlist (.txt) are not in `git ls-files '*.md'`, so the
# gate cannot match its own rows. Verified rather than assumed: both extensions are
# outside the glob.
for m in mds:
    text = open(m, encoding='utf-8', errors='replace').read()
    lines = text.split('\n')
    flat = ' '.join(text.split())          # line-break evasion check, GATE 3's lesson (a)
    for fig, note in figs:
        seen_on_a_line = False
        for i, line in enumerate(lines, 1):
            if fig not in line:
                continue
            seen_on_a_line = True
            # MARK EVERY MATCHING ROW USED, not just the first (fixed on this gate's
            # first run, before it shipped). Two anchors can legitimately land on one
            # line: TR-2 v1.23 quotes v1.19's "not reconstructible from the stated
            # errors" AND says where 1.4 came from, so both rows match line 654. A
            # break-on-first left the second looking dead and printed a [note] that was
            # a pure false alarm — the drift audit crying wolf on its own first run is
            # exactly how a real dead row later gets ignored.
            hits = [(anchor, cls, why)
                    for (af, afig, anchor), (cls, why) in allow.items()
                    if af == m and afig == fig and anchor in line]
            if hits:
                for anchor, _, _ in hits:
                    used.add((m, fig, anchor))
                exempt.append((m, i, fig, hits[0][1], hits[0][2]))
            else:
                bad.append((m, i, fig, note, line.strip()))
        # A figure visible only after whitespace normalisation spans a hard wrap, so no
        # single line carries it and the anchor rule cannot be applied. Report it as a
        # finding rather than passing it: this is exactly the evasion that hid the
        # conflict-theorem scope from GATE 3 until 2026-08-01.
        if not seen_on_a_line and fig in flat:
            spans.append((m, fig, note))

for m, i, fig, note, line in bad:
    print(f'  [FAIL] {m}:{i} — retracted figure "{fig}" restated with no supersession marker')
    print(f'         WHY: {note}')
    print(f'         LINE: {line[:150]}')
for m, fig, note in spans:
    print(f'  [FAIL] {m} — retracted figure "{fig}" present only after whitespace')
    print(f'         normalisation, so it spans a hard wrap and cannot be anchored.')
    print(f'         WHY: {note}')

opens = [e for e in exempt if e[3] != 'meta-mention' and e[3] != 'historical']
for m, i, fig, cls, why in opens:
    print(f'  [OPEN] {m}:{i} "{fig}" — {why}')
dead = [k for k in allow if (k[0], k[1], k[2]) not in used]
for k in dead:
    print(f'  [note] allowlist row matched nothing this run: {k[0]} "{k[1]}" @ "{k[2][:40]}"')
    print(f'         Either the text was fixed (delete the row) or the anchor drifted.')

nbad = len(bad) + len(spans)
if not nbad:
    byclass = {}
    for _, _, _, cls, _ in exempt:
        byclass[cls] = byclass.get(cls, 0) + 1
    tally = ', '.join(f'{v} {k}' for k, v in sorted(byclass.items())) or 'none'
    print(f'  [ok] {len(figs)} registered retracted figure(s); every occurrence in '
          f'{len(mds)} markdown files is an allowlisted narration ({tally})')
sys.exit(1 if nbad else 0)
PY
}

# ----------------------------------------------------------------------------------
gate_links() {
  local rc=0
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
  rc=$?

  return $rc
}

# ----------------------------------------------------------------------------------
gate_secrefs() {
  local rc=0
  # -- GATE 4b (added 2026-08-01, unit r70-serialize) --------------------------------
  # The half of a cross-reference that phase 1 CANNOT see. A pointer like
  #     [CRITIQUE.md](../documentation/CRITIQUE.md) Q1
  # has a LINK target that resolves perfectly — the file exists — so phase 1 passes it,
  # while the part a reader actually follows ("go to section Q1") is dead. Six such
  # pointers to a non-existent "CRITIQUE.md Q1" survived every gate in this file for
  # months for exactly that reason.
  #
  # SCOPE, deliberately narrow: only DELIMITED section references are checked —
  #   FILE.md §"Quoted Name"     and     FILE.md Q<n>
  # Undelimited `FILE.md §Some words` is NOT checked: prose runs on past the section
  # name with no terminator, so the extracted "name" is whatever the sentence happened
  # to say next, and a first cut of this gate produced ~60 findings of which most were
  # mis-parses. A gate that cries wolf gets switched off. If you want an undelimited
  # reference checked, quote it.
  #
  # MATCH RULE: the reference text, normalised (case, smart quotes, dashes, emphasis,
  # trailing punctuation), must appear as a substring of some heading in the target
  # file; "…" in the reference acts as a gap, its fragments matched in order. That is
  # the convention the repo already uses, e.g. CRITIQUE.md §"Pre-registered tests …
  # Davis (2012)" against a much longer real heading.
  #
  # WHY-IT-FIRED: every finding prints the target file it resolved to and the reason,
  # not just a verdict — and allowlisted entries are re-printed every run as [OPEN]
  # with a count, so the known-dangling set can never quietly become invisible.
  #
  # OWN DISPATCH NAME (`secrefs`, added 2026-08-02, item A3). 4b used to live inside
  # gate_links, and the self-test asserted on `doc_gates.sh links` — one exit code
  # covering BOTH phases. A phase-1 failure for any unrelated reason would have satisfied
  # that assertion with 4b never having fired: [ok] printed for a gate that was not
  # exercised, which is precisely the untested-test shape this file's header warns about
  # (and the shape GATE 8's manual fire-proof shipped in). `links` still runs both, so
  # `all` and every existing caller are unchanged; the SELF-TEST now targets `secrefs`,
  # whose exit code no other gate can supply.
  echo "== GATE 4b: plain-text section references resolve to a real heading =="
  python3 - <<'PY'
import os, re, sys, subprocess
MDLINK = re.compile(r'\[([^\]]*)\]\(([^)\s]+)\)')
HEAD   = re.compile(r'^#+\s+(.*?)\s*$', re.M)
SEC_Q  = re.compile(r'([\w./+-]+\.md)\s*§\s*"([^"]+)"')
SEC_N  = re.compile(r'([\w./+-]+\.md)\s+(Q\d+)\b')
ALLOW  = 'documentation/DOC_GATE_SECREF_ALLOWLIST.txt'

def norm(s):
    s = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', s)
    for a, b in (('’', "'"), ('‘', "'"), ('“', '"'), ('”', '"'),
                 ('–', '-'), ('—', '-')):
        s = s.replace(a, b)
    s = re.sub(r'[`*_~"]', '', s)
    s = re.sub(r'\s+', ' ', s)
    return s.strip().strip('.,;:').lower()

mds = subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True).stdout.split()
heads, bybase = {}, {}
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    heads[os.path.realpath(m)] = [norm(h) for h in HEAD.findall(txt)]
    bybase.setdefault(os.path.basename(m), []).append(os.path.realpath(m))

allow, allow_why = set(), {}
if os.path.exists(ALLOW):
    for ln in open(ALLOW, encoding='utf-8'):
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.rstrip('\n').split('\t')
        if len(f) >= 4:
            allow.add((f[0], f[1], norm(f[2])))
            allow_why[(f[0], f[1], norm(f[2]))] = f[3]

bad, opened = [], []
for m in mds:
    base = os.path.dirname(m) or '.'
    for lineno, line in enumerate(open(m, encoding='utf-8', errors='replace'), 1):
        flat = MDLINK.sub(lambda mo: mo.group(2), line)   # [text](path) -> path
        hits  = [(p, s) for p, s in SEC_Q.findall(flat)]
        hits += [(p, s) for p, s in SEC_N.findall(SEC_Q.sub(' ', flat))]
        for path, sec in hits:
            if path.startswith(('http://', 'https://')):
                continue
            dest = None
            for cand in (os.path.realpath(os.path.join(base, path)), os.path.realpath(path)):
                if cand in heads:
                    dest = cand; break
            if dest is None:                       # bare "CRITIQUE.md", no path
                same = bybase.get(os.path.basename(path), [])
                if len(same) == 1:
                    dest = same[0]
            if dest is None:
                continue                           # file-level resolution is phase 1's job
            want = norm(sec)
            if not want:
                continue
            parts = [p.strip() for p in re.split('…|\\.\\.\\.', want) if p.strip()]
            found = False
            for h in heads[dest]:
                pos, ok = 0, True
                for p in parts:
                    i = h.find(p, pos)
                    if i < 0:
                        ok = False; break
                    pos = i + len(p)
                if ok:
                    found = True; break
            if found:
                continue
            rel = os.path.relpath(dest)
            key = (m, rel, want)
            (opened if key in allow else bad).append((m, lineno, rel, sec, key))

for m, ln, d, s, key in bad:
    print(f'  [FAIL] {m}:{ln} -> {d} §"{s}"')
    print(f'         WHY: no heading in {d} contains the normalised text "{norm(s)}"')
for m, ln, d, s, key in opened:
    print(f'  [OPEN] {m}:{ln} -> {d} §"{s}"  ({allow_why.get(key, "allowlisted")})')
if opened:
    print(f"  [note] {len(opened)} allowlisted dangling reference(s) above are OPEN DEFECTS, "
          f"not exemptions — see {ALLOW}")
if not bad:
    print(f"  [ok] every delimited section reference resolves to a real heading "
          f"({len(mds)} markdown files scanned)")
sys.exit(1 if bad else 0)
PY
  [ $? -ne 0 ] && rc=1
  return $rc
}

# `links` keeps running BOTH phases, so `all` and every existing caller are unchanged.
gate_links_and_secrefs() {
  local rc=0
  gate_links   || rc=1
  gate_secrefs || rc=1
  return $rc
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
# Allowlist entries are "path:line" with an optional TAB-separated content anchor: a literal
# substring identifying the reviewed sentence.
#
# WHY the anchor is now the PRIMARY key (2026-08-01, second revision). The file:line form drifts,
# and drifts constantly: both entries in the allowlist drifted within a single day. The TR-4
# calibration row was written at :119, two lines were inserted above it, and the entry then
# (a) failed to suppress the real row at :121 and (b) silently covered whatever had moved into
# :119. Direction (b) is the dangerous one — an unreviewed line inheriting somebody else's
# suppression. The HISTORY.md entry then repeated the pattern: correct at :5563 when written,
# pushed to :5566 hours later by an unrelated insertion three lines above it.
#
# Matching an anchored entry by (file, anchor) instead of (file, line) fixes both directions at
# once. Direction (b) becomes impossible — suppression now REQUIRES the reviewed text, so no
# unreviewed line can inherit it no matter how the file is edited. And benign renumbering stops
# raising a WARN that carries no information. The recorded line number is kept as documentation
# and audited below, so a stale or dead entry is still reported rather than silently accumulating.
# ITEM A8, DECIDED 2026-08-02: the recorded line number is GONE from the format. The key is
# (file, anchor) and nothing else.
#
# The item offered three options — (i) keep and refresh by hand, (ii) drop it and lose the
# dead-entry audit, (iii) have the gate REWRITE the recorded line, self-healing. (iii) was
# the favourite. All three are declined, because (ii)'s stated cost is not real and (iii)
# has a cost that was not stated:
#
#   * "(ii) loses the dead-entry audit" is FALSE. Read the audit below: of its four
#     branches, three — file gone, anchor gone, anchor matches several lines — are driven
#     entirely by the ANCHOR. Only the fourth, "anchor now sits at :N, update the recorded
#     line", uses the number, and that branch is precisely the recurring [note] the item
#     complains about. Dropping the number costs the noise and keeps the whole audit.
#   * (iii) would make a gate a writer. The self-test REFUSES TO RUN unless the tree is
#     clean, so a self-healing gate run first would break the next run's precondition, and
#     a writer needs its own mutation case proving it wrote the RIGHT line — a new
#     instrument to trust, added to solve a documentation problem.
#
# The locator readers actually want is still printed: the gate resolves the anchor and
# reports the line it found, every run. A computed location cannot go stale.
#
# An entry with no anchor now SUPPRESSES NOTHING. It used to suppress by line number, which
# is the dangerous direction this whole design exists to close: an unreviewed line inheriting
# somebody else's exemption after an edit above it.
anchorless = []    # entries with no anchor: reported, and deliberately inert
anchored = {}      # file -> [anchor] — matched by content, immune to renumbering
if os.path.exists(allow):
    for l in open(allow, encoding='utf-8'):
        l = l.rstrip('\n')
        if not l.strip() or l.lstrip().startswith('#'): continue
        parts = l.split('\t')
        key = parts[0].strip()
        anc = parts[1].strip() if len(parts) > 1 and parts[1].strip() else None
        if anc is None:
            anchorless.append(key)
        else:
            anchored.setdefault(key, []).append(anc)
EST = r'estimate|estimated|Knuth|\bCI\b|confidence|Monte'
EX  = r'\bexact|\bproven|\bproved'
files = [p for p in subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True)
         .stdout.split()]
seen = 0; bad = 0; hits = set()   # hits: which registry rows actually occur in the corpus
# GATE 5b state (2026-08-02, item A4). Cost formula, evaluated before writing it: F files x
# L lines, F ~ 250 and the whole tracked-markdown corpus ~10 MB, held once.
TEXT = {}          # f -> lines, kept only for files that actually carry a registry value
unmarked = {}      # f -> [(ln, val, want, line)] occurrences with NEITHER kind of token
marked = {}        # f -> {ln} occurrences that DID carry a token (either side)
n_unmarked = 0
for f in files:
    _lines = open(f, encoding='utf-8', errors='replace').read().splitlines()
    for ln, line in enumerate(_lines, 1):
        for val, want in rows:
            if re.fullmatch(r'[\d.]+', val) and ',' not in val:
                if not re.search(re.escape(val) + r'\s*[×x]\s*10', line): continue
            elif val not in line:
                continue
            seen += 1
            hits.add(val)
            TEXT[f] = _lines
            etoks = sorted(set(t.lower() for t in re.findall(EST, line, re.I)))
            xtoks = sorted(set(t.lower() for t in re.findall(EX, line, re.I)))
            he, hx = bool(etoks), bool(xtoks)
            if not he and not hx:
                unmarked.setdefault(f, []).append((ln, val, want, line))
                n_unmarked += 1
            else:
                marked.setdefault(f, set()).add(ln)
            conflict = (want == 'exact' and he and not hx) or (want == 'estimate' and hx and not he)
            if conflict:
                if any(a in line for a in anchored.get(f, ())): continue
                # RECORD WHICH QUANTITY AND WHICH TOKEN (2026-08-02, #65). "this line reads
                # otherwise" made the reader re-run the classifier by eye to find the word that
                # tripped it — and on a report-only gate, an unexplained WARN is one nobody
                # actions. Name the registry value, its METHODS status, and the exact status
                # token(s) matched on the wrong side.
                got = ", ".join(f'"{t}"' for t in (xtoks if want == 'estimate' else etoks))
                side = 'exact/proven' if want == 'estimate' else 'estimate'
                print(f"  [WARN] {f}:{ln} — quantity {val[:28]} is '{want}' in METHODS, but this line "
                      f"carries {side} token(s) {got} and no '{want}' marker")
                print(f"         {line.strip()[:170]}")
                bad += 1
if bad == 0:
    print(f"  [ok] {seen} occurrences of {len(hits)}/{len(rows)} canonical quantities "
          f"all carry a consistent status")
else:
    print(f"  (report-only: if a hit is a legitimate exact-vs-estimate COMPARISON, add its 'file:line' to {allow})")
# Audit the allowlist itself. A suppression that no longer corresponds to real text is a
# permission nobody reviewed and nobody can see; it must be reported, not accumulate silently.
for fpath, entries in sorted(anchored.items()):
    if not os.path.exists(fpath):
        print(f"  [note] allowlist: {fpath} no longer exists — prune its {len(entries)} entry/entries")
        continue
    text = open(fpath, encoding='utf-8', errors='replace').read().splitlines()
    for anc in entries:
        hits = [i for i, l in enumerate(text, 1) if anc in l]
        if not hits:
            print(f"  [note] allowlist: {fpath} anchor no longer appears in the file — prune it")
            print(f"         anchor: {anc[:120]}")
        elif len(hits) > 1:
            print(f"  [note] allowlist: {fpath} anchor matches {len(hits)} lines {hits[:6]} — "
                  "suppression is broader than one reviewed sentence; make it more specific")
        else:
            # The locator, COMPUTED not recorded (item A8). Printed as [ok] rather than
            # [note] because a live, single-match exemption is not a defect and must not
            # compete for attention with the two branches above, which are.
            print(f"  [ok]   allowlist: {fpath}:{hits[0]} exemption live (matched by content)")
for key in sorted(anchorless):
    print(f"  [note] allowlist: \"{key}\" has no TAB-separated anchor, so it SUPPRESSES NOTHING "
          "and is ignored. Add an anchor: the format is file<TAB>anchor, no line number.")

# ---------------------------------------------------------------------------------
# GATE 5b — a canonical quantity restated with NO epistemic marker among siblings that
# carry one (2026-08-02, item A4).
#
# WHY. GATE 5 above fires only when a line carries a status token that CONTRADICTS
# METHODS. The two unlabelled TR-9 ledger cells fixed under #23 carried no token at all
# and were therefore invisible to it BY CONSTRUCTION — TR-9's own v1.19 row says so in as
# many words: "GATE 5 ... fires on a status token contradicting METHODS, and these cells
# carried no status token at all." An omission is the commoner shape and it was ungated.
#
# WHY IT IS SCOPED TO MIXED TABLES, and not to every unmarked occurrence. "Report every
# occurrence with neither token" measures at the noise floor printed below — most prose
# mentions of a canonical number legitimately carry no marker, and a gate that prints
# hundreds of lines every run is one whose output reviewers learn to skip (the same
# erosion items A8 and B2 describe). The DEFECT shape is narrower and is exactly what
# TR-9 v1.19 describes: "In a table where siblings are explicitly marked exact, an
# unmarked cell reads as one more exact count." So the reported class is: an unmarked
# occurrence inside a markdown table block where ANOTHER line of the SAME table carries a
# marker. The bare count is printed alongside, so the noise floor is MEASURED rather than
# assumed, and a future implementer can widen the class knowing what widening costs.
#
# REPORT-ONLY, with its own allowlist. The allowlist is a SEPARATE file from GATE 5's on
# purpose: 5 and 5b are different classes, and one file would let a suppression written
# for a reviewed exact-vs-estimate COMPARISON silently also exempt an unmarked cell on the
# same line. Anchored entries only — the line-number-only form drifted twice in one day.
alw5b = 'documentation/DOC_GATE_UNMARKED_ALLOWLIST.txt'
anc5b = {}
if os.path.exists(alw5b):
    for l in open(alw5b, encoding='utf-8'):
        l = l.rstrip('\n')
        if not l.strip() or l.lstrip().startswith('#'): continue
        parts = l.split('\t')
        if len(parts) < 2 or not parts[1].strip():
            print(f"  [note] {alw5b}: entry without a TAB-separated anchor is ignored — {parts[0][:80]}")
            continue
        fpath, _, lno = parts[0].strip().rpartition(':')
        anc5b.setdefault(fpath, []).append((lno, parts[1].strip()))

def table_blocks(lines):
    """Maximal runs of consecutive markdown table lines, as (start, end) 1-based inclusive."""
    blocks, start = [], None
    for i, l in enumerate(lines, 1):
        if l.lstrip().startswith('|'):
            if start is None: start = i
        elif start is not None:
            blocks.append((start, i - 1)); start = None
    if start is not None: blocks.append((start, len(lines)))
    return blocks

def header_labels(header, row, val, want):
    """True if the table HEADER already labels the column this value sits in.

    Found by running 5b for the first time, which is the point of running it: 4 of its 6
    initial findings were cells in tables whose header column IS the label — TR-4's
    "| Layer | Exact value | Prior Knuth estimate | ... |" and SEARCH_SPACE_SIZE's
    "| quantity | estimate | 95% CI | rel. error |". Those cells are not unlabelled; the
    label is one row up, where a per-line classifier cannot see it. Reporting them would
    have been the false-positive flood that gets a report-only gate ignored.

    Column-aware rather than whole-header: a table with BOTH an exact and an estimate
    column (TR-4 has exactly that) would otherwise be self-exempting in both directions.
    """
    hc = [c.strip() for c in header.split('|')]
    rc = [c.strip() for c in row.split('|')]
    pat = EST if want == 'estimate' else EX
    idx = [i for i, c in enumerate(rc) if val in c]
    if idx and len(hc) == len(rc):
        return bool(re.search(pat, hc[idx[0]], re.I))
    return False                        # ragged table: fall through and report it

found5b = 0
print("  -- 5b: unmarked canonical quantity among marked siblings in the same table --")
for f in sorted(unmarked):
    mk = marked.get(f, set())
    if not mk:
        continue
    for lo, hi in table_blocks(TEXT[f]):
        if not any(lo <= m <= hi for m in mk):
            continue                      # no marked sibling in this table — not the class
        header = TEXT[f][lo - 1]
        for ln, val, want, line in unmarked[f]:
            if not (lo <= ln <= hi):
                continue
            # A REVISION-HISTORY row is exempt, exactly as GATE 3 exempts one: a changelog
            # records what was said at a date and quotes figures in passing; demanding an
            # epistemic marker there would fire on every historical entry forever. Both of
            # 5b's remaining initial findings were changelog rows.
            if line.lstrip().startswith('| v'):
                continue
            if header_labels(header, line, val, want):
                continue
            if any(a in line for _, a in anc5b.get(f, ())):
                continue
            sibs = sorted(m for m in mk if lo <= m <= hi)
            # RECORD WHY IT FIRED (#65): the quantity, its METHODS status, the table it sits
            # in, and the sibling line whose marker makes the omission readable as a claim.
            print(f"  [WARN] {f}:{ln} — quantity {val[:28]} is '{want}' in METHODS and carries NO "
                  f"status marker, inside the table at :{lo}-{hi} whose sibling line(s) "
                  f"{sibs[:4]} DO carry one")
            print(f"         {line.strip()[:170]}")
            found5b += 1
if found5b == 0:
    print(f"  [ok] no unmarked canonical quantity sits in a table whose siblings are marked")
else:
    print(f"  (report-only: label the cell, or add 'file:line<TAB>anchor' to {alw5b})")
print(f"  [measured] noise floor: {n_unmarked} of {seen} registry-value occurrences carry no "
      f"status token at all; {found5b} of those are in a MIXED table, which is the reported class")
for fpath, entries in sorted(anc5b.items()):
    if not os.path.exists(fpath):
        print(f"  [note] {alw5b}: {fpath} no longer exists — prune its {len(entries)} entry/entries")
        continue
    txt = open(fpath, encoding='utf-8', errors='replace').read().splitlines()
    for lno, anc in entries:
        hh = [i for i, l in enumerate(txt, 1) if anc in l]
        if not hh:
            print(f"  [note] {alw5b}: {fpath}:{lno} anchor no longer appears — prune it")
        elif len(hh) > 1:
            print(f"  [note] {alw5b}: {fpath}:{lno} anchor matches {len(hh)} lines {hh[:6]} — "
                  "make it more specific")
        elif str(hh[0]) != str(lno):
            print(f"  [note] {alw5b}: {fpath}:{lno} anchor now sits at :{hh[0]} — update the recorded line")
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
      if tr '\n' ' ' < "$f" | tr -s ' ' | grep -qF -- "$np"; then
        # RECORD WHERE (2026-08-02, item A5 / #65). This printed a bare filename, so a
        # maintainer given a 900-line generator had to re-run the search by hand to find
        # the annotation string — the same debugging cost #65 removed from GATE 3 and
        # GATE 5. Cite the line; fall back to the filename when the hit is only visible
        # after normalisation, which is the case a hard-wrapped Python string produces.
        local gln
        gln=$(grep -nF -- "$np" "$f" 2>/dev/null | head -1 | cut -d: -f1)
        if [ -n "$gln" ]; then hits="$hits $f:$gln"; else hits="$hits $f(spans-lines)"; fi
      fi
    done
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing in a figure generator: \"$phrase\""
      echo "         matched as the fixed string: \"$np\"   ($note)"
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
# OPERATOR RULE (2026-08-01): "if you ever need to know if a large enumeration
# completed, it should be cataloged with a sha256 as a canonical hash." So the
# authority is not the mere APPEARANCE of a budget in the registry — it is a
# budget that carries a sha256. The first version of this gate took any <N>T
# token from the file, which silently admitted 1120T (mentioned only in a
# power-law extrapolation sentence, and CANCELLED on 2026-08-01) and 900T. A doc
# could then have said "the 1120T run" and passed. Require a sha in the vicinity.
reg = open('documentation/CANONICAL_HASHES.md', errors='replace').read()
REACHED = set()
MENTIONED = set()          # appears in the registry at all — but appearing is not attesting
for m in re.finditer(r'\b([0-9.]+T)\b', reg):
    MENTIONED.add(m.group(1))
    window = reg[max(0, m.start() - 600): m.end() + 600]
    if re.search(r'\b[0-9a-f]{16,64}\b', window):     # a sha256 (or its prefix) attests completion
        REACHED.add(m.group(1))
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
        # SAY WHY IT IS NOT ATTESTED (2026-08-02, #65). "not a budget any canonical reached"
        # states the verdict but hides the test, and the two ways of failing that test need
        # different fixes: a budget absent from the registry may be a typo or an invented run,
        # while one PRESENT but sha-less is the 1120T shape — a real number quoted from a
        # projection sentence and then written up as though it had been run. Operator rule:
        # completion is attested by a sha256 in CANONICAL_HASHES.md, nothing weaker.
        why = ("appears in documentation/CANONICAL_HASHES.md but with no sha256 within +/-600 "
               "chars of any mention — mentioned is not attested"
               if m.group(1) in MENTIONED else
               "does not appear in documentation/CANONICAL_HASHES.md at all")
        print(f"  [FINDING] {f}:{ln} — \"{m.group(0)}\" names a run after budget {m.group(1)}, which")
        print(f"            {why}, and no disposition is stated nearby.")
        print(f"            sha-attested budgets: {', '.join(sorted(REACHED)) or '(none)'}")
        bad = 1
if not bad:
    print("  [ok] no frozen run status; every budget-named run carries a disposition")
sys.exit(bad)
PY
}

# ---------------------------------------------------------------------------
# GATE 9 — the technical-report banner must be byte-identical across every TR,
# and must not re-assert the over-claim it replaced.
#
# WHY (2026-08-01, unit d72-banner): all 11 reports opened with
#   "Every claim is machine-verifiable; see the Verification Guide."
# which is FALSE as written, and TR-8 said so about ITSELF at its own line 24:
# the dof-matched baseline it leans on has no artifact, command, seed or code
# path anywhere in the repo. reports/README.md had already been corrected to
# disclose the exceptions, so the suite was publishing one standard in its index
# and a stronger, false one on all 11 covers.
#
# The banner is the single most-copied string in the corpus — exactly the shape
# that drifts silently. Before this gate existed it ALREADY had: TR-2 and TR-8
# carried "…see the Verification Guide below." while nine others did not, and
# nothing in the repo could see it. That two-variant split is this gate's
# known-answer anchor: it was verified to FAIL on the pre-fix tree, naming those
# two files, before the corrected banner was applied.
#
# Byte-identity ALONE is not enough — eleven files reverted together are still
# byte-identical. So the gate also pins the discriminating clause, bans the
# retracted over-claim, and holds reports/README.md to the same clause so the
# index cannot drift back to a blanket promise.
#
# SAFETY: fixed-string containment and endswith() only — no regex at all.
gate_banner() {
  echo "== GATE 9: report banner byte-identical across all TRs =="
  python3 - <<'PY'
import glob, sys

MARK    = 'not peer-reviewed'
KEEP    = 'argued, not verified'          # the discriminating scope clause
RETRACT = 'Every claim is machine-verifiable'
MAXBLK  = 8                               # a REPORT banner is a short italic block
MAXIDX  = 24                              # the INDEX banner also enumerates the exceptions

def block(path, cap=MAXBLK):
    """Return (block_text, marker_line_count, 1-based line no) for the banner.

    `cap` is per-role and not cosmetic. The first version of this gate used the
    tight report cap of 8 for reports/README.md too; the index banner is 11+
    lines because it names each disclosed exception, so the gate reported it as
    "never closed its italic" and the index check never actually ran. It looked
    like a finding and was a bug in the checker — caught only because the gate
    was run against its known-answer anchor before being trusted.
    """
    lines = open(path, errors='replace').read().split('\n')
    hits = [i for i, l in enumerate(lines) if MARK in l]
    if len(hits) != 1:
        return None, len(hits), 0
    i = hits[0]
    blk = []
    for l in lines[i:i + cap]:
        blk.append(l)
        if l.rstrip().endswith('*'):      # closing italic marker
            return '\n'.join(blk), 1, i + 1
    return None, -1, i + 1                # never closed its italic within `cap`

trs = sorted(glob.glob('reports/TR*.md'))
bad = 0
variants = {}                             # block text -> [file:line]
if not trs:
    print('  [FAIL] no reports/TR*.md found — wrong working directory?')
    sys.exit(1)

for f in trs:
    blk, n, ln = block(f)
    if blk is None:
        bad = 1
        if n == -1:
            print(f'  [FAIL] {f}:{ln} — banner never closes its italic within {MAXBLK} lines')
        else:
            print(f'  [FAIL] {f} — expected exactly 1 line containing "{MARK}", found {n}')
        continue
    variants.setdefault(blk, []).append(f'{f}:{ln}')

print(f'  scanned {len(trs)} reports/TR*.md; {len(variants)} distinct banner(s)')

if len(variants) > 1:
    bad = 1
    print(f'  [FAIL] the banner is NOT byte-identical: {len(variants)} variants in use')
    ranked = sorted(variants.items(), key=lambda kv: -len(kv[1]))
    for n, (blk, files) in enumerate(ranked, 1):
        print(f'    variant {n} — {len(files)} report(s): {", ".join(files)}')
        for l in blk.split('\n'):
            print(f'        | {l}')
    # WHY it fired, not just THAT it fired: name the line where two variants diverge.
    a = ranked[0][0].split('\n')
    b = ranked[1][0].split('\n')
    for i in range(max(len(a), len(b))):
        x = a[i] if i < len(a) else '<no line>'
        y = b[i] if i < len(b) else '<no line>'
        if x != y:
            print(f'    first divergence at block line {i + 1}:')
            print(f'        variant 1 > {x}')
            print(f'        variant 2 > {y}')
            break

for blk, files in variants.items():
    if RETRACT in blk:
        bad = 1
        print(f'  [FAIL] the retracted over-claim "{RETRACT}" is back in: {", ".join(files)}')
    if KEEP not in blk:
        bad = 1
        print(f'  [FAIL] banner lacks its scope clause "{KEEP}" in: {", ".join(files)}')

# The index must not promise more than the covers do.
idx = 'reports/README.md'
iblk, n, ln = block(idx, MAXIDX)
if iblk is None:
    bad = 1
    print(f'  [FAIL] {idx} — no single well-formed banner block (marker lines: {n})')
elif RETRACT in iblk:
    bad = 1
    print(f'  [FAIL] {idx}:{ln} — index banner re-asserts "{RETRACT}"')
elif KEEP not in iblk:
    bad = 1
    print(f'  [FAIL] {idx}:{ln} — index banner lacks "{KEEP}"; the index may not')
    print(f'         promise more than the {len(trs)} report covers do')

if not bad:
    first = next(iter(variants)).split('\n')[0]
    print(f'  [ok] all {len(trs)} TR banners byte-identical; scope clause present; index aligned')
    print(f'       | {first}')
sys.exit(bad)
PY
}

# ===========================================================================
# SELF-TEST — mutation testing. Run: scripts/doc_gates.sh --selftest
#
# WHY (2026-08-01): these seven gates had never been observed to FAIL. GATE 7
# was VACUOUS on the day it was written — its suppression list contained the
# word "budget", and the stale table it was built for has a "Budget" column
# header three lines above the frozen status, so it passed cleanly on its own
# motivating defect. A gate nobody has watched fire is an untested test, and
# a green row of [ok] from an untested gate reads as coverage while providing
# none. That is the same failure as verify_archive.sh sampling zero shards and
# reporting PASS.
#
# METHOD: inject one known defect at a time into the real tree, run only the
# gate that should catch it, assert it FAILS, then revert with git checkout.
# Mutation testing rather than synthetic fixtures, deliberately: the gates read
# real paths (CANONICAL_HASHES.md, solve.py, viz/), so a fixture would test a
# different program than the one that runs in anger.
#
# SAFETY: refuses to run unless the tree is clean, so it can never destroy
# uncommitted work; every mutation is reverted immediately after its assertion,
# including on failure.
# ===========================================================================
if [ "${1:-}" = "--selftest" ]; then
  cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "REFUSING: working tree is not clean. This self-test mutates real files and"
    echo "reverts them with 'git checkout --'; that would discard your uncommitted work."
    exit 2
  fi
  PASS=0
  # assert_fires <label> <primary-file> <gate-name> <python-mutation>
  #
  # The revert is `git checkout -- .`, NOT `-- "$file"` (corrected 2026-08-01, same-day
  # re-review). The GATE 6 case mutates whatever `glob('viz/*.py')` returns first — a path
  # the caller cannot name, and glob order is not guaranteed — while its <file> column said
  # viz/README.md. So that mutation was never reverted by its own assertion; only the
  # blanket `git checkout -- .` after the last case cleaned it up, leaving every later
  # assertion running against a mutated tree. Reverting everything is correct here and
  # costs nothing: the self-test refuses to start unless the tree is already clean, so
  # there is never uncommitted work for `-- .` to discard. <file> is kept as documentation
  # of the mutation's primary target.
  assert_fires() {
    local label="$1" file="$2" gate="$3" mut="$4"
    python3 -c "$mut" || { echo "  [SKIP] $label ($file) — could not inject (anchor moved)"; return; }
    if bash "$0" "$gate" >/dev/null 2>&1; then
      echo "  [FAIL] $label — $gate did NOT fire on an injected defect"
      PASS=1
    else
      echo "  [ok]   $label — $gate fires"
    fi
    git checkout -- . 2>/dev/null
  }

  # assert_fires_why <label> <gate-name> <evidence-ERE> <python-mutation>
  #
  # ITEM A5 (task #65, the assertion half). `assert_fires` checks an EXIT CODE and nothing
  # else, so it cannot tell "the gate fired for the reason I injected" from "the gate fired
  # for some unrelated reason and my mutation was never seen". Every classifier gate now
  # prints the token/anchor/registry note that drove its verdict; this harness is what makes
  # that printing load-bearing instead of decorative — the assertion FAILS if the WHY line
  # does not name the injected thing. Modelled on assert_gen_fires, which already did this
  # for GATE 8; generalised here so every classifier class can carry one.
  assert_fires_why() {
    local label="$1" gate="$2" want="$3" mut="$4" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject (anchor moved), so the"
                           echo "         assertion did NOT run. A skipped assertion is not a pass."
                           PASS=1; git checkout -- . 2>/dev/null; return; }
    out=$(bash "$0" "$gate" 2>&1); rc=$?
    git checkout -- . 2>/dev/null
    if [ "$rc" -eq 0 ]; then
      echo "  [FAIL] $label — $gate did NOT fire on an injected defect"; PASS=1; return
    fi
    if printf '%s' "$out" | grep -qE -- "$want"; then
      echo "  [ok]   $label — $gate fires, and WHY names: $want"
    else
      echo "  [FAIL] $label — $gate fired, but its output never names \"$want\","
      echo "         so the assertion cannot tell this firing from an unrelated one."
      PASS=1
    fi
  }

  # assert_stays_clean <label> <gate-name> <python-mutation>
  #
  # The other half of any allowlist-bearing gate: proof that the EXEMPTION is driven by what
  # it claims to be driven by. Without it, a green gate is equally consistent with "the
  # allowlist is correct" and "the allowlist swallows the whole file".
  assert_stays_clean() {
    local label="$1" gate="$2" mut="$3"
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject; assertion did NOT run."
                           PASS=1; git checkout -- . 2>/dev/null; return; }
    if bash "$0" "$gate" >/dev/null 2>&1; then
      echo "  [ok]   $label — exempted, as the allowlist says it should be"
    else
      echo "  [FAIL] $label — $gate fired on text its allowlist covers"
      PASS=1
    fi
    git checkout -- . 2>/dev/null
  }

  echo "== DOC GATES SELF-TEST (mutation) =="

  # GATE 1 is REPORT-ONLY (`return 0`) and only inspects integers of >=12 digits. Asserting a
  # non-zero exit was wrong twice over: it can never exit non-zero, and the number I first
  # mutated has 10 digits so the gate would not look at it either way. Assert on its OUTPUT.
  # This also means "DOC GATES: PASS" has never included gate 1's findings — a real limit on
  # what that banner attests, now stated in the banner itself.
  # Anchor: the |C1nC2nC4nC5| exact count in README.md — 40 digits, non-round, and present
  # in more than one doc, which is exactly the shape gate 1 looks for. Flipping its last
  # digit creates a same-length near-twin sharing the first 10 digits: the corrupted-digit
  # case the gate exists to catch.
  python3 -c "s=open('README.md').read()
a='1,097,051,278,789,181,790,036,112,071,176,579,186,688'
assert a in s, 'anchor moved'
open('README.md','w').write(s.replace(a, a[:-1]+'9', 1))" 2>/dev/null \
    && { G1OUT=$(bash "$0" numbers 2>&1)
         if printf '%s' "$G1OUT" | grep -q 'WARN'; then
           echo "  [ok]   GATE 1 cross-file numbers — emits a WARN (report-only gate)"
         else
           echo "  [FAIL] GATE 1 cross-file numbers — no WARN on an injected near-twin"
           printf '%s\n' "$G1OUT" | sed 's/^/           > /' | head -4
           PASS=1
         fi
         git checkout -- README.md 2>/dev/null; } \
    || echo "  [SKIP] GATE 1 — anchor moved"

  # A5/#65: assert the MATCHED STRING, not just the exit code. GATE 3's registry holds
  # morphology-independent stems, so several rows can be live at once and an exit code alone
  # cannot say which one saw the injection.
  assert_fires_why "GATE 3 retracted phrasing" retract \
    'matched as the fixed string: "hard floor k>=13"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe ordering has a hard floor k>=13 by construction.\n')"

  # GATE 3b — THREE cases, and the positive one is its OWN MOTIVATING EXAMPLE rather than a
  # synthetic string. reports/evidence/r11/PHASE2_README.md is the artifact that actually
  # carried an uncorrected "1.4σ above" after TR-2 v1.19 retracted it, surviving until a
  # human read it on 2026-08-02 (TR-2 v1.23). The mutation puts that sentence back, as a bare
  # assertion with none of the narration the allowlist anchors on.
  assert_fires_why "GATE 3b retracted figure restated (its own motivating example)" \
    retract-figures 'retracted figure "1\.4σ" restated' \
"p='reports/evidence/r11/PHASE2_README.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nThe pooled value sits 1.4σ above the Phase-1 single run.\n')"

  # GATE 3b, LINE-BREAK EVASION. GATE 3's hardening note (a) records that a retracted phrase
  # once hid inside a hard wrap where line-based grep could not see it. GATE 3b matches
  # per-line so it can anchor exemptions, which reintroduces that exposure — the normalised
  # whole-file pass is the compensating branch, and this is the only thing that exercises it.
  assert_fires_why "GATE 3b retracted figure split across a hard wrap" \
    retract-figures 'spans a hard wrap' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nThe ledger prices C2 at marginal\n4.6 bits under that convention.\n')"

  # GATE 3b NEGATIVE CONTROL — the exemption must be driven by the ANCHOR, not by the file.
  # Same file as an existing allowlist row, same figure, and the row's anchor text present:
  # this must NOT fire. Without it, the [ok] above is equally consistent with the allowlist
  # having quietly exempted reports/evidence/ wholesale.
  assert_stays_clean "GATE 3b negative control — an anchored narration is exempt" \
    retract-figures \
"p='reports/evidence/r11/README.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nRestated for the index: this figure read 1.4σ until 2026-08-02.\n')"

  assert_fires "GATE 4 internal links" documentation/GUIDE.md links \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nSee [the missing doc](NO_SUCH_FILE_XYZ.md).\n')"

  # GATE 4b, in the EXACT shape of its motivating defect: the link target resolves
  # (CRITIQUE.md exists, so phase 1 stays green) and only the section half is dead.
  # If this assertion ever passes-through, the extension has stopped seeing the one
  # class it was written for. The quoted form §\"...\" was verified by the same
  # method when the gate was written.
  #
  # DISPATCH (corrected 2026-08-02, item A3): this used to run `links`, which is GATE 4
  # AND 4b behind one exit code — so a phase-1 failure for any unrelated reason would
  # have satisfied the assertion with 4b never fired, printing [ok] for an unexercised
  # gate. It now runs `secrefs`, which is 4b alone; no other gate can supply that
  # exit code. (Compensated manually once, with phase 1 verified green by hand — a
  # by-hand guarantee the permanent assertion did not carry, which is the same shape as
  # GATE 8's hand-taken fire-proof going stale across a refactor.)
  # A5/#65: also assert the WHY line, which names the target file and the normalised text
  # that failed to resolve. 4b has an allowlist, so an exit code alone cannot distinguish
  # "fired on my injection" from "fired on a pre-existing entry that fell out of the list".
  assert_fires_why "GATE 4b dangling section ref" secrefs \
    'WHY: no heading in .* contains the normalised text "q7"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nPriced as data ([CRITIQUE.md](CRITIQUE.md) Q7).\n')"

  # A5/#65: assert the matched string AND that a file:line is cited (the location GATE 6
  # did not print until 2026-08-02). `\.py:[0-9]` is what proves the location half.
  assert_fires_why "GATE 6 figure generators" figures \
    'matched as the fixed string: "hard floor k>=13"' \
"import glob,sys
c=[f for f in glob.glob('viz/*.py')]
sys.exit(1) if not c else None
s=open(c[0]).read()
open(c[0],'w').write(s+'\n# hard floor k>=13\n')"

  assert_fires_why "GATE 6 figure generators name the LINE, not just the file" figures \
    'viz/.*\.py:[0-9]+  — regenerate' \
"import glob,sys
c=[f for f in glob.glob('viz/*.py')]
sys.exit(1) if not c else None
s=open(c[0]).read()
open(c[0],'w').write(s+'\n# hard floor k>=13\n')"

  # A5/#65: GATE 7's LIVE list has seven keywords and its DISPO suppression list has
  # sixteen; the finding line names the keyword that matched, and that is what this asserts.
  assert_fires_why "GATE 7 frozen run status" liveness \
    'status frozen in the present tense: "in flight"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe ladder build is in flight and the log is 3,666 lines and growing.\n')"

  # A5/#65: 1120T is the MENTIONED-but-sha-less shape, not the absent-from-registry shape,
  # and the two need different fixes — so assert the branch, not just the failure.
  assert_fires_why "GATE 7 unreached budget" liveness \
    'with no sha256 within' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe 1120T run reproduced the published ladder exactly.\n')"

  # GATE 9, in the EXACT shape the operator specified: a SYNTHETIC SINGLE-FILE EDIT.
  # The injected change is one space — whitespace only, still valid markdown, still
  # closing its italic, and semantically identical. A gate that normalised whitespace
  # (the obvious "robustness" tweak) would pass this and would not be a byte-identity
  # gate at all. If this assertion ever stops firing, the gate has stopped being one.
  assert_fires "GATE 9 banner drift (1 byte, 1 file)" reports/TR5_SYMMETRY.md banner \
"s=open('reports/TR5_SYMMETRY.md').read()
a='interpretation are argued, not verified.*'
assert a in s, 'anchor moved'
open('reports/TR5_SYMMETRY.md','w').write(s.replace(a,'interpretation are argued, not verified. *',1))"

  # GATE 9's second branch: the 11 covers can be perfectly uniform while the INDEX
  # drifts back to a blanket promise. Byte-identity across the reports cannot see
  # that, so the branch is exercised separately — an unexercised branch is untested.
  assert_fires "GATE 9 index drops the scope clause" reports/README.md banner \
"s=open('reports/README.md').read()
a='interpretation are argued, not verified.'
assert a in s, 'anchor moved'
open('reports/README.md','w').write(s.replace(a,'interpretation are sound.',1))"

  # GATE 10 POSITIVE: deleting a committed line from the corrections ledger must fire it.
  # The deleted line is chosen from the middle of the file rather than the end, so the
  # assertion cannot be satisfied by a "file got shorter" check that would miss a
  # reword-in-place — the defect this gate actually exists for.
  # DISPATCH (2026-08-02, item A7): `appendonly-head`, not `appendonly`. Since 10b landed,
  # `appendonly` is two gates behind one exit code and this assertion would be satisfiable
  # by either — the same untested-test shape A3 fixed for GATE 4b.
  assert_fires "GATE 10a append-only vs HEAD (committed line deleted)" documentation/CORRECTIONS.md appendonly-head \
"L=open('documentation/CORRECTIONS.md').read().split(chr(10))
assert len(L) > 60, 'ledger too short to mutate meaningfully'
del L[len(L)//2]
open('documentation/CORRECTIONS.md','w').write(chr(10).join(L))"

  # GATE 10 NEGATIVE CONTROL. An APPEND must NOT fire it. Without this the [ok] above
  # proves only that the gate is capable of failing, not that it is capable of passing
  # — and a gate that always fails is turned off within a day, which is how the
  # container-level exemptions in this file got there in the first place.
  python3 -c "open('documentation/CORRECTIONS.md','a').write(chr(10)+'### CX-selftest — an appended line.'+chr(10))" 2>/dev/null \
    && { if bash "$0" appendonly >/dev/null 2>&1; then
           echo "  [ok]   GATE 10 negative control — a pure APPEND does not fire it"
         else
           echo "  [FAIL] GATE 10 fired on a pure append; it is not an append-only gate"
           bash "$0" appendonly 2>&1 | sed 's/^/           > /' | head -5
           PASS=1
         fi
         git checkout -- . 2>/dev/null; } \
    || echo "  [SKIP] GATE 10 negative control — could not append"

  # =========================================================================
  # GATE 10b — THREE assertions (added 2026-08-02, item A7), because they prove three
  # different things and the first one alone would have passed on the BROKEN gate.
  #
  # (i) runs in the real tree and proves the DETECTOR works. It is dispatched to
  #     `appendonly-history`, which is 10b alone — the A3 lesson applied here, since a
  #     deleted line fires 10a too and a shared dispatch name would let the assertion be
  #     satisfied by the half that was never in question.
  #
  # (ii) and (iii) are the DIFFERENTIATORS, and they cannot be staged in this repo: the
  #     defect A7 reports only exists once the removal has been COMMITTED (ii) or the
  #     history REWRITTEN (iii), and the self-test may do neither to the real tree. They
  #     are staged in throwaway repos built by `cp "$0"` — so they exercise THIS script,
  #     not a re-implementation of it, which is the difference between a fire-proof and a
  #     clever proxy.
  assert_fires "GATE 10b vs history (a line of the OLDEST committed version deleted)" \
    documentation/CORRECTIONS.md appendonly-history \
"import subprocess
f='documentation/CORRECTIONS.md'
revs=subprocess.run(['git','rev-list','HEAD','--',f],capture_output=True,text=True).stdout.split()
assert revs, 'the ledger has no history to test against'
old=subprocess.run(['git','show',revs[-1]+':'+f],capture_output=True,text=True).stdout.split(chr(10))
cur=open(f,encoding='utf-8').read().split(chr(10))
cand=[l for l in old if l.strip() and l in cur]
assert cand, 'no line of the oldest committed version survives to delete'
cur.remove(cand[len(cand)//2])
open(f,'w',encoding='utf-8').write(chr(10).join(cur))"

  # scratch_appendonly <label> <setup-shell-run-inside-the-scratch-repo>
  #   Asserts BOTH verdicts at once: 10a must be GREEN (that is the blindness A7 reports)
  #   and 10b must be RED (that is the fix). Asserting only 10b would still pass in a
  #   world where 10a had caught it — and "10a does not catch it" is the whole claim.
  scratch_appendonly() {
    local label="$1" setup="$2" d rcA rcB
    d=$(mktemp -d) || { echo "  [SKIP] $label — no tmpdir"; return; }
    ( set -e
      mkdir -p "$d/scripts" "$d/documentation"
      cp "$0" "$d/scripts/doc_gates.sh"
      cd "$d"
      export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
      export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid
      git init -q .
      git symbolic-ref HEAD refs/heads/main
      printf 'CX-1 first entry.\nCX-2 second entry.\nCX-3 third entry.\n' \
        > documentation/CORRECTIONS.md
      git add -A && git commit -qm 'ledger: three entries'
      eval "$setup" ) >/dev/null 2>&1 \
      || { echo "  [SKIP] $label — scratch setup failed (its own premise did not hold)"
           rm -rf "$d"; return; }
    ( cd "$d" && bash scripts/doc_gates.sh appendonly-head    >/dev/null 2>&1 ); rcA=$?
    ( cd "$d" && bash scripts/doc_gates.sh appendonly-history >/dev/null 2>&1 ); rcB=$?
    rm -rf "$d"
    if [ "$rcA" -eq 0 ] && [ "$rcB" -ne 0 ]; then
      echo "  [ok]   $label — 10a green on it (the blindness), 10b fires (the fix)"
    else
      echo "  [FAIL] $label — expected 10a rc=0 and 10b rc!=0; got 10a rc=$rcA, 10b rc=$rcB"
      PASS=1
    fi
  }

  # (ii) COMMIT THE REMOVAL — no unusual git required, which is why it is the likelier of
  #      the two. After the second commit the working copy and HEAD agree perfectly.
  scratch_appendonly "GATE 10b vs a COMMITTED removal (working copy == HEAD)" \
"printf 'CX-1 first entry.\nCX-3 third entry.\n' > documentation/CORRECTIONS.md
git add -A && git commit -qm 'tidy: drop CX-2'"

  # (iii) HISTORY REWRITE. This is the case an ancestor-walk alone CANNOT close, and the
  #       setup asserts that premise rather than assuming it: if the pre-rewrite commit
  #       were still an ancestor of HEAD the walk would see it, the scenario would be
  #       testing nothing, and the setup exits 3 so the case reports [SKIP] instead of a
  #       false [ok]. With the premise held, refs/remotes/origin/main is the only baseline
  #       still holding the dropped line.
  scratch_appendonly "GATE 10b vs an AMEND that drops a PUBLISHED line" \
"git update-ref refs/remotes/origin/main HEAD
orig=\$(git rev-parse HEAD)
printf 'CX-1 first entry.\nCX-3 third entry.\n' > documentation/CORRECTIONS.md
git add -A && git commit -q --amend -m 'ledger: three entries'
if git merge-base --is-ancestor \"\$orig\" HEAD; then exit 3; fi"

  # GATE 11: a registry row with no ledger entry must fire it. Injected as a NEW registry
  # row rather than by deleting a ledger entry, because deletion would fire GATE 10 and
  # the assertion would pass for the wrong reason — the two gates must be shown to be
  # independent, not merely both red.
  assert_fires "GATE 11 ledger completeness (unrecorded retraction)" documentation/RETRACTED_PHRASES.tsv ledger \
"open('documentation/RETRACTED_PHRASES.tsv','a').write(
 'a synthetic phrasing that was never published'+chr(9)+'__none__'+chr(9)+'Self-test row: no ledger entry exists for it, so GATE 11 must fail.'+chr(10))"

  # GATE 5, added 2026-08-02 with the #65 work. The old note said this gate could not be
  # mutation-tested because doing so "would require editing a canonical quantity" — which
  # was true only of the mutation shape assumed. APPENDING a new sentence that quotes 5.21
  # with the wrong status edits no existing value at all, and reverts like every other
  # GUIDE.md mutation here. The stated reason for a coverage gap is worth re-testing, not
  # just inheriting: that is the same "recorded state that was not true" class this suite
  # exists for. Assert on OUTPUT, like GATE 1: gate 5 is report-only and always exits 0.
  # The assertion is on the WHY text, not merely on the presence of a WARN — a gate that
  # fires without saying what it matched is the defect #65 was raised to fix.
  python3 -c "s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+chr(10)+'The exact figure 5.21 x 10^31 is a proven count.'+chr(10))" 2>/dev/null \
    && { G5OUT=$(bash "$0" status 2>&1)
         if printf '%s' "$G5OUT" | grep -q "carries exact/proven token(s)"; then
           echo "  [ok]   GATE 5 epistemic status — WARNs and names the tokens it matched"
         else
           echo "  [FAIL] GATE 5 did not fire, or fired without naming what it matched"
           printf '%s\n' "$G5OUT" | sed 's/^/           > /' | head -4
           PASS=1
         fi
         git checkout -- documentation/GUIDE.md 2>/dev/null; } \
    || echo "  [SKIP] GATE 5 — could not append"

  # -----------------------------------------------------------------------
  # GATE 5's ALLOWLIST — three assertions (2026-08-02, item A8). Re-keying the allowlist on
  # (file, anchor) alone deleted the drift branch that had a live negative control (an
  # entry recorded at :9999 fired it). Deleting a branch deletes its proof, so the
  # replacement proofs are written here rather than assumed. All three are OUTPUT
  # assertions: GATE 5 is report-only and always exits 0.
  #
  # (1) DRIFT IMMUNITY — the whole point of A8. Insert a line ABOVE the anchored TR-4
  #     sentence. The exemption must still resolve (to a line one greater) and the run must
  #     produce NO [note] at all: under the old scheme this exact edit produced one.
  python3 -c "s=open('reports/TR4_SIZE_OF_THE_SPACE.md').read()
a='*none — no exact value exists*'
assert a in s, 'anchor moved'
i=s.index(a); j=s.rindex(chr(10), 0, i)
open('reports/TR4_SIZE_OF_THE_SPACE.md','w').write(s[:j]+chr(10)+'<!-- selftest: a line inserted above the anchored row -->'+s[j:])" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if printf '%s' "$A8OUT" | grep -q 'TR4_SIZE_OF_THE_SPACE.md:124 exemption live' \
            && ! printf '%s' "$A8OUT" | grep -q '\[note\] allowlist'; then
           echo "  [ok]   GATE 5 allowlist drift immunity — anchor moved :123 -> :124, still live, no [note]"
         else
           echo "  [FAIL] GATE 5 allowlist did not survive an insertion above its anchor"
           printf '%s\n' "$A8OUT" | grep -E 'allowlist' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         git checkout -- . 2>/dev/null; } \
    || { echo "  [FAIL] GATE 5 allowlist drift case — could not inject; assertion did NOT run."; PASS=1; }

  # (2) DEAD ANCHOR still audited. This is the branch A8's option (ii) was said to cost,
  #     and it does not: it never read the line number.
  python3 -c "open('documentation/DOC_GATE_STATUS_ALLOWLIST.txt','a').write(
'documentation/HISTORY.md'+chr(9)+'a sentence that appears nowhere in the corpus'+chr(10))" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if printf '%s' "$A8OUT" | grep -q 'anchor no longer appears in the file'; then
           echo "  [ok]   GATE 5 allowlist dead-anchor audit — fires, and says prune it"
         else
           echo "  [FAIL] GATE 5 allowlist accepted an anchor matching nothing, silently"
           PASS=1
         fi
         git checkout -- . 2>/dev/null; } \
    || { echo "  [FAIL] GATE 5 dead-anchor case — could not inject; assertion did NOT run."; PASS=1; }

  # (3) AN UNANCHORED ENTRY SUPPRESSES NOTHING. Under the old scheme it suppressed by line
  #     number, which is the direction that let an unreviewed line inherit somebody else's
  #     exemption. The entry injected here names the exact file:line GATE 5 warns about in
  #     assertion (1) above, so if it still suppressed, the WARN would vanish.
  python3 -c "s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+chr(10)+'The exact figure 5.21 x 10^31 is a proven count.'+chr(10))
n=len(open('documentation/GUIDE.md').read().split(chr(10)))-1
open('documentation/DOC_GATE_STATUS_ALLOWLIST.txt','a').write('documentation/GUIDE.md:%d'%n+chr(10))" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if printf '%s' "$A8OUT" | grep -q 'SUPPRESSES NOTHING' \
            && printf '%s' "$A8OUT" | grep -q "carries exact/proven token(s)"; then
           echo "  [ok]   GATE 5 unanchored allowlist entry — reported AND inert"
         else
           echo "  [FAIL] GATE 5 unanchored entry suppressed a WARN, or was not reported"
           printf '%s\n' "$A8OUT" | grep -E 'allowlist|WARN' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         git checkout -- . 2>/dev/null; } \
    || { echo "  [FAIL] GATE 5 unanchored case — could not inject; assertion did NOT run."; PASS=1; }

  # GATE 5b (item A4), asserted against ITS OWN MOTIVATING EXAMPLE rather than a synthetic
  # table: the mutation reverts TR-9's C3 ledger cell to the bare-number form it carried
  # before #23 fixed it. That is the defect the class exists for, and TR-9 v1.19 states
  # that GATE 5 could not see it. Report-only, so the assertion is on the OUTPUT.
  #
  # WHY THE ASSERTION NAMES THE FILE AND THE WORD "NO status marker": 5b was narrowed TWICE
  # after its first run — a column-aware header exemption and a changelog-row exemption,
  # which between them took its live findings from 6 to 0. A gate narrowed to silence is
  # indistinguishable from a gate narrowed to precision unless something re-proves it still
  # fires, and neither narrowing may be allowed to swallow this case.
  # A DRIFTED ANCHOR IS A FAILURE HERE, NOT A SKIP. Written as a [SKIP] first, and the very
  # first run printed "[SKIP] GATE 5b — anchor moved" because the injector's `%` had been
  # written `%%` (a printf habit; this is a plain double-quoted bash string). The assertion
  # never ran and the suite still reported PASS — GATE 8's failure exactly, reproduced
  # within an hour of writing the rule down. So: no silent skip. If TR-9's cell is legitimately
  # reworded, this must go red and be re-anchored by hand, because a fire-proof that opts
  # itself out is not a proof.
  #
  # The mutation is NOT injected via `python3 -c` for the same reason: the shell layer is
  # where the escaping went wrong. It is written to a file and run, so the string reaching
  # python is the string in this script.
  G5BMUT=$(mktemp)
  cat > "$G5BMUT" <<'G5BPY'
p = 'reports/TR9_PRICING_THE_CONSTRAINTS.md'
a = '1.3287×10³⁸ (**estimate** — Knuth random-probe, 95% CI [1.3283, 1.3292]×10³⁸, 0.02%)'
s = open(p, encoding='utf-8').read()
assert s.count(a) == 1, 'anchor moved: found %d occurrences' % s.count(a)
open(p, 'w', encoding='utf-8').write(s.replace(a, '1.3287×10³⁸', 1))
G5BPY
  if python3 "$G5BMUT" 2>&1; then
    G5BOUT=$(bash "$0" status 2>&1)
    if printf '%s' "$G5BOUT" | grep -q 'TR9_PRICING_THE_CONSTRAINTS.md:70 .* carries NO status marker'; then
      echo "  [ok]   GATE 5b unmarked-among-marked — fires on the pre-#23 TR-9 ledger cell"
    else
      echo "  [FAIL] GATE 5b did not fire on the defect it was written for"
      printf '%s\n' "$G5BOUT" | sed 's/^/           > /' | head -6
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 5b — could not inject its anchor, so the assertion did NOT run."
    echo "         Re-anchor it against TR-9's C3 ledger cell; a skipped fire-proof is not a proof."
    PASS=1
  fi
  rm -f "$G5BMUT"
  git checkout -- reports/TR9_PRICING_THE_CONSTRAINTS.md 2>/dev/null

  # =========================================================================
  # GATE 8 — THREE mutation cases, ONE regeneration (added 2026-08-02, item A1).
  #
  # WHY THIS IS HERE AT ALL. GATE 8's fire-proof was taken BY HAND at df4ddc9. Its
  # invocation was rewritten hours later at 91129a4 and the proof was never re-run —
  # which is exactly how a ONE-DIRECTIONAL comparison shipped and attested "matches
  # exactly" over a DELETED line (b0ee2f8). A hand-taken proof is not a proof of the
  # code that ships; only an assertion that re-runs is.
  #
  # WHY IT ASSERTS ON THE EVIDENCE, NOT THE EXIT CODE. The bug it exists to catch —
  # comparing in one direction only — still exits non-zero on a SUBSTITUTION, because a
  # substitution leaves an added line behind as well. An exit-code assertion would have
  # passed on the broken gate. Each case therefore names the exact counted verdict
  # GATE 8 must print, so "0 added, 1 missing" (deletion, the direction that was
  # missing) is asserted as a number and cannot be satisfied by any other finding.
  #
  # THE COST, AND WHAT PAYS IT. Each GATE 8 invocation regenerates example/ from
  # roae.py — three runs, ~45 s each, so three naive cases would cost ~7 minutes. They
  # share ONE regeneration through DOC_GATES_GEN_CACHE, keyed on roae.py's sha256:
  # measured 135 s for the first case and 0.08 s for each of the others.
  GEN_CACHE=$(mktemp -d)

  # assert_gen_fires <label> <evidence-ERE> <python-mutation>
  #   <evidence-ERE> must match a line of GATE 8's output.
  assert_gen_fires() {
    local label="$1" want="$2" mut="$3" out rc
    python3 -c "$mut" || { echo "  [SKIP] $label — could not inject (anchor moved)"; return; }
    out=$(DOC_GATES_GEN_CACHE="$GEN_CACHE" bash "$0" generated 2>&1); rc=$?
    git checkout -- . 2>/dev/null
    if [ "$rc" -eq 0 ]; then
      echo "  [FAIL] $label — GATE 8 did NOT fire on an injected defect"
      PASS=1; return
    fi
    if printf '%s\n' "$out" | grep -Eq -- "$want"; then
      echo "  [ok]   $label — GATE 8 fires, and WHY matches: $want"
    else
      echo "  [FAIL] $label — GATE 8 fired, but not for the asserted reason"
      echo "         expected a line matching: $want"
      printf '%s\n' "$out" | grep -E '\[FAIL\]' | head -3 | sed 's/^/           got > /'
      PASS=1
    fi
  }

  # CASE 1 — DELETION, the direction the shipped comparison could not see, in the exact
  # shape of the 2026-08-01 demonstration: remove the nuclear-attractor line from
  # example/report.txt. 0 added / 1 missing is the whole point — a `comm -13`-only gate
  # scores 0 added and reports [ok].
  assert_gen_fires "GATE 8 deletion from a shipped artifact" \
'example/report\.txt vs roae\.py --all: 0 added, 1 missing' \
"p='example/report.txt'
L=open(p,encoding='utf-8').read().split(chr(10))
h=[i for i,x in enumerate(L) if 'terminal attractor' in x]
assert len(h)==1, 'anchor moved'
del L[h[0]]
open(p,'w',encoding='utf-8').write(chr(10).join(L))"

  # CASE 2 — SUBSTITUTION, the shape of defect (a): example/README.md was a hand-edited
  # copy of report.md differing by one word. One letter, in a line roae.py prints
  # UNCONDITIONALLY (print_complements' static preamble), so the case cannot be flaked by
  # a Monte Carlo verdict landing in a different branch.
  assert_gen_fires "GATE 8 one-word substitution in a shipped artifact" \
'example/README\.md vs roae\.py --markdown: 1 added, 1 missing' \
"p='example/README.md'
a=\"is an organizing feature of the sequence's structure\"
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(s.replace(a,a.replace('organizing','organising'),1))"

  # CASE 3 — the PDF leg (item A2), which has no other proof. Mutating report.html trips
  # leg 4 as well, so the assertion targets leg 5's OWN verdict line: proof that the
  # pdftotext/tag-strip comparison ran and disagreed, not merely that the gate went red
  # for some earlier reason.
  assert_gen_fires "GATE 8 PDF no longer renders the shipped HTML" \
'example/report\.pdf vs example/report\.html: 1 line\(s\) only in the PDF, 1 only in the HTML' \
"p='example/report.html'
a=\"is an organizing feature of the sequence's structure\"
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(s.replace(a,a.replace('organizing','organising'),1))"

  # CASE 4 — a DELETED shipped artifact. Found by Phase-4'ing this batch and asking what
  # every leg does when its input is not there: all five used to [skip] on `! -f`, so
  # `rm example/report.pdf` passed in silence. Absence is the strongest mismatch there is.
  assert_gen_fires "GATE 8 shipped artifact deleted outright" \
'example/report\.pdf is tracked in git but missing from the working tree' \
"import os
assert os.path.exists('example/report.pdf'), 'anchor moved'
os.remove('example/report.pdf')"

  rm -rf "$GEN_CACHE"

  # THE COVERAGE GAP, STATED IN FULL. One gate is not mutation-tested here, and until
  # 2026-08-02 this note named only one gap at a time -- it said "GATE 2 + GATE 5" and
  # silently omitted GATE 8. A self-test that under-reports its own gap is the defect it
  # tests for, so the list is enumerated against the assert_fires calls above:
  #   covered: 1 (output), 3, 3b x3 (+negative control), 4, 4b, 5 (output) + its
  #            ALLOWLIST x3 (drift immunity, dead anchor, unanchored-and-inert),
  #            5b (output), 6 x2, 7 x2, 8 x4, 9 x2, 10a (+negative control), 10b x3, 11
  #   Of those, the ones asserting WHY and not merely an exit code (item A5 / #65):
  #            3, 3b x2, 4b, 6 x2, 7 x2, 8 x4, 11. GATES 1, 5 and 5b are report-only and
  #            already assert on output. GATES 4, 9, 10a/10b are structural, not
  #            classifier-driven: there is no matched token for them to name.
  #   NOT covered: 2 -- would mutate solve.py, a costlier revert than the assurance is
  #                     worth; it has FIRED in anger (13 undocumented flags, 2026-07/08).
  # The old note said GATE 8 was excluded because ~90s regeneration "exceeds the
  # orchestrator's budget". MEASURED 2026-08-02 on the orchestrator: 45 s and 31 MB peak
  # RSS per run. The budget claim was inherited, not measured, and it was wrong; the
  # shared cache makes the marginal case free regardless.
  echo "  [note] not mutation-tested: GATE 2 (would mutate solve.py). It has FIRED in anger."

  git checkout -- . 2>/dev/null
  echo
  [ "$PASS" -eq 0 ] && echo "DOC GATES SELF-TEST: PASS" || echo "DOC GATES SELF-TEST: FAIL"
  exit "$PASS"
fi

# ---------------------------------------------------------------------------
# GATE 8 — generated artifacts must match their generator.
#
# WHY (2026-08-01, two independent instances in one day):
#  (a) example/README.md was a hand-edited copy of example/report.md. They
#      differed by exactly one line — "keeps COMPLEMENTS unusually near one
#      another" where roae.py:774 emits "OPPOSITES". Someone edited the artifact
#      instead of the source, and it survived indefinitely.
#  (b) I did the same thing while fixing the C8 defect: patched roae.py AND
#      string-patched the four shipped artifacts, two independent routes to the
#      same text. Committed in dbba77d, caught by the operator, reverted.
#
# No other gate covers this. Retraction, link, status, number and liveness gates
# all pass on a hand-edited artifact, because the text is not retracted, the
# links resolve and the numbers are self-consistent. The defect is only visible
# by RE-RUNNING THE GENERATOR.
#
# Comparison is DIGIT-STRIPPED. roae.py seeds nothing by default, so Monte Carlo
# figures legitimately change every run; a byte-diff would fail always and the
# gate would be turned off within a day. Stripping digits compares the PROSE and
# the structure, which is where hand-edits live. Numeric drift is gate 1's job.
#
# COVERAGE, stated exactly (extended 2026-08-02, item A2). Until then the gate covered
# report.txt, report.md and README.md only — example/report.html and example/report.pdf
# were shipped generator-derived artifacts with NO generator-match check of any kind,
# and report.html is the file that was hand-patched in dbba77d. Both are now covered,
# by two DIFFERENT strategies, because a PDF cannot be line-diffed:
#
#   report.html  -> compared against a fresh `roae.py --html` (like-for-like, same as
#                   the other three: digit-stripped line diff, both directions).
#   report.pdf   -> compared against the SHIPPED example/report.html, by extracting the
#                   PDF's text with pdftotext and the HTML's text by tag-stripping, then
#                   comparing the two as MULTISETS of digit-stripped lines.
#
# The PDF leg deliberately does NOT regenerate. wkhtmltopdf(report.html) is the ONLY
# route by which report.pdf is produced (roae.py's export_html shells out to it), so
# "the PDF's text equals the shipped HTML's text" is exactly the derivation invariant,
# and checking it against the shipped HTML costs nothing and is deterministic. The
# chain closes: generator -> html (leg 4) -> pdf (leg 5). Regenerating a PDF and
# diffing it would instead compare two renderings whose page breaks move whenever a
# Monte Carlo figure changes width — a gate that fails for reasons nobody can act on.
# MEASURED before shipping: on the artifacts as committed the two bags differ by
# exactly ZERO lines once <title>/<style>/<script> are stripped.
#
# Cost: three roae.py runs (~45 s each, measured 2026-08-02 at 31 MB peak RSS), so this
# is NOT part of `all`. Run it before publishing. See DOC_GATES_GEN_CACHE below for how
# the self-test pays that cost ONCE across multiple invocations.
#
# DOC_GATES_GEN_CACHE (added 2026-08-02, item A1): a caller may name a directory to hold
# the regenerated reference artifacts. If it already holds a complete set generated from
# the CURRENT roae.py, it is reused instead of regenerating. This exists so the self-test
# can run several mutation cases for one regeneration; it is opt-in precisely because a
# silently-reused stale cache would be a false clear, and it self-invalidates on the only
# input that can change the answer — roae.py's own sha256.
gate_generated() {
  echo "== GATE 8: generated artifacts match their generator =="
  # Compare LIKE FOR LIKE. The first draft diffed every artifact against `--all`
  # stdout, so the markdown files failed on their own headers -- a gate that
  # flags correct files gets switched off, which is the mistake ops_gates GATE 4
  # made the same day. Each artifact is now compared against the invocation that
  # actually produces it.
  #
  # Digit-stripped: roae.py seeds nothing by default, so Monte Carlo figures
  # legitimately change every run. Stripping digits compares PROSE and structure,
  # which is where hand-edits live. Numeric drift is gate 1's business.
  local tmp rc=0 owned=0 cur_sha
  command -v python3 >/dev/null 2>&1 || { echo "  [skip] no python3"; return 0; }
  cur_sha=$(sha256sum roae.py 2>/dev/null | cut -d' ' -f1)

  if [ -n "${DOC_GATES_GEN_CACHE:-}" ]; then
    tmp="$DOC_GATES_GEN_CACHE"; mkdir -p "$tmp" || return 1
  else
    tmp=$(mktemp -d) || return 1; owned=1
  fi

  # Reuse only if the cache is COMPLETE and was built from THIS roae.py. A cache keyed on
  # nothing would turn a stale directory into a false clear — the failure mode this whole
  # suite exists to stop — so the key is the generator's own sha256, the only input that
  # can change what the reference should be.
  if [ -s "$tmp/fresh.txt" ] && [ -s "$tmp/report.md" ] && [ -s "$tmp/report.html" ] \
     && [ -n "$cur_sha" ] && [ "$(cat "$tmp/.roae_sha" 2>/dev/null)" = "$cur_sha" ]; then
    echo "  reusing regeneration cache $tmp (roae.py sha256 $(printf '%.12s' "$cur_sha")… unchanged)"
  else
    # `--markdown` and `--html` are run WITHOUT `--all` and from inside $tmp, because that
    # is what the generator actually does: roae.py's main() short-circuits on args.markdown
    # (returns before the --all dispatch), and export_markdown()/export_html() open their
    # files in the CWD. Spelling it "--all --markdown > file" is the recipe that corrupted
    # example/ once already; the gate should not model it. (Function names, not line
    # numbers, on purpose — a recorded line number is the thing that drifts, cf. the
    # GATE 5 allowlist.)
    echo "  regenerating (3 runs, ~45s each, unseeded): --all to stdout, then --markdown and --html into a temp dir"
    rm -f "$tmp/.roae_sha"
    if ! timeout 300 python3 roae.py --all > "$tmp/fresh.txt" 2>/dev/null; then
      echo "  [FAIL] the generator itself did not run cleanly"; [ "$owned" = 1 ] && rm -rf "$tmp"; return 1
    fi
    ( cd "$tmp" && timeout 300 python3 "$OLDPWD/roae.py" --markdown >/dev/null 2>&1 )
    ( cd "$tmp" && timeout 300 python3 "$OLDPWD/roae.py" --html     >/dev/null 2>&1 )
    [ -n "$cur_sha" ] && printf '%s\n' "$cur_sha" > "$tmp/.roae_sha"
  fi
  [ -f "$tmp/report.md" ] || { echo "  [skip] --markdown produced no report.md"; [ "$owned" = 1 ] && rm -rf "$tmp"; return 0; }

  _norm() { sed 's/[0-9]//g; s/[[:space:]]\+/ /g' "$1" | grep -v '^ *$' | sort; }
  # BOTH DIRECTIONS. The first version compared one way only (`comm -13`: lines the
  # ARTIFACT has that the generator does not), so a pure DELETION from a shipped
  # artifact passed -- and passed while printing "matches ... exactly", which is the
  # same over-attestation this suite exists to catch. Demonstrated 2026-08-01 by
  # deleting the nuclear-attractor line from example/report.txt: the gate said [ok].
  # Substitutions were caught only because they leave an added line behind as well.
  # A MISSING shipped artifact is a FAILURE, not a skip (2026-08-02). Every leg below used
  # to `[skip]` on `! -f`, so `rm example/report.pdf` passed the gate in silence — the same
  # false-clear shape as the one-directional comparison, and reached the same way: by asking
  # what the gate does when its input is not there. Absence is only a skip for an artifact
  # git does not track; for a tracked one it is the strongest possible mismatch.
  _present() {   # <path>
    [ -f "$1" ] && return 0
    if git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; then
      echo "  [FAIL] $1 is tracked in git but missing from the working tree"
      echo "         A shipped artifact that is absent is not a passing artifact — regenerate it."
      return 2
    fi
    echo "  [skip] $1 absent (not tracked, so nothing is shipped to check)"
    return 1
  }
  _cmp() {   # <artifact> <reference> <label>
    _present "$1"; case $? in 1) return 0;; 2) return 1;; esac
    local extra missing
    extra=$(comm -13 <(_norm "$2") <(_norm "$1") | wc -l)
    missing=$(comm -23 <(_norm "$2") <(_norm "$1") | wc -l)
    if [ "$extra" -eq 0 ] && [ "$missing" -eq 0 ]; then
      echo "  [ok]   $1 matches $3 exactly (digit-stripped, both directions)"
    else
      echo "  [FAIL] $1 vs $3: $extra added, $missing missing (normalised lines) -- hand-edited?"
      comm -13 <(_norm "$2") <(_norm "$1") | head -3 | sed 's/^/           +added   > /'
      comm -23 <(_norm "$2") <(_norm "$1") | head -3 | sed 's/^/           -missing > /'
      echo "         Fix the SOURCE (roae.py) and regenerate; never edit the artifact."
      echo "         CAUTION (recipe corrected 2026-08-01): only --all writes to stdout."
      echo "         --markdown and --html OPEN THEIR OWN FILES in the cwd (roae.py's"
      echo "         export_markdown / export_html) and print only a status line, so"
      echo "         'roae.py --markdown > f' writes 'Markdown report written to"
      echo "         report.md' INTO f and leaves the real report at the repo root."
      echo "         Run them from example/ instead:"
      echo "           python3 roae.py --all > example/report.txt"
      echo "           ( cd example && python3 ../roae.py --markdown )   # writes example/report.md"
      echo "           cp example/report.md example/README.md"
      echo "           ( cd example && python3 ../roae.py --html )       # writes report.html + report.pdf"
      return 1
    fi
  }
  _cmp example/report.txt  "$tmp/fresh.txt"   "roae.py --all"      || rc=1
  _cmp example/report.md   "$tmp/report.md"   "roae.py --markdown" || rc=1
  _cmp example/README.md   "$tmp/report.md"   "roae.py --markdown" || rc=1
  if [ -f "$tmp/report.html" ]; then
    _cmp example/report.html "$tmp/report.html" "roae.py --html"    || rc=1
  else
    echo "  [skip] --html produced no report.html"
  fi

  # LEG 5 — example/report.pdf is the wkhtmltopdf rendering of example/report.html.
  # No regeneration: see the header. Multiset (not sorted-diff) comparison, because
  # pdftotext reflows page-by-page and the ORDER of identical lines carries no
  # information here; what a hand-edit changes is WHICH lines exist.
  _cmp_pdf() {   # <pdf> <html>
    _present "$1"; case $? in 1) return 0;; 2) return 1;; esac
    _present "$2"; case $? in 1) return 0;; 2) return 1;; esac
    command -v pdftotext >/dev/null 2>&1 || { echo "  [skip] no pdftotext — $1 not checked"; return 0; }
    python3 - "$1" "$2" <<'PY'
import collections, html, re, subprocess, sys, tempfile, os
pdf, htm = sys.argv[1], sys.argv[2]
with tempfile.TemporaryDirectory() as d:
    txt = os.path.join(d, 'p.txt')
    if subprocess.run(['pdftotext', '-layout', pdf, txt],
                      capture_output=True).returncode != 0:
        print(f"  [skip] pdftotext could not read {pdf}"); sys.exit(0)
    pdftext = open(txt, encoding='utf-8', errors='replace').read()
h = open(htm, encoding='utf-8', errors='replace').read()
for tag in ('style', 'script', 'title'):     # <title> duplicates the <h1>; not body text
    h = re.sub(r'(?s)<%s\b.*?</%s>' % (tag, tag), '', h)
# `</?[A-Za-z!]` and NOT `<[^>]+>`: roae.py emits unescaped "<->" inside <pre>, and the
# permissive pattern eats it — which silently made 69 lines look mismatched while the
# artifacts were in fact identical (measured 2026-08-02 while designing this leg).
h = html.unescape(re.sub(r'</?[A-Za-z!][^>]*>', '', h))
def bag(t):
    c = collections.Counter()
    for ln in t.splitlines():
        ln = re.sub(r'\s+', ' ', re.sub(r'[0-9]', '', ln)).strip()
        if ln: c[ln] += 1
    return c
P, H = bag(pdftext), bag(h)
only_p, only_h = P - H, H - P
if not only_p and not only_h:
    print(f"  [ok]   {pdf} is the rendering of {htm} "
          f"({sum(H.values())} normalised lines, both directions)")
    sys.exit(0)
print(f"  [FAIL] {pdf} vs {htm}: {sum(only_p.values())} line(s) only in the PDF, "
      f"{sum(only_h.values())} only in the HTML")
for x, n in list(only_p.items())[:3]: print(f"           +pdf-only  ({n}) > {x[:100]}")
for x, n in list(only_h.items())[:3]: print(f"           -html-only ({n}) > {x[:100]}")
print("         The PDF's ONLY production route is wkhtmltopdf(report.html) via roae.py's")
print("         export_html, so a difference means one of the two was edited by hand.")
print("         Fix roae.py, then: ( cd example && python3 ../roae.py --html )")
sys.exit(1)
PY
  }
  _cmp_pdf example/report.pdf example/report.html || rc=1

  [ "$owned" = 1 ] && rm -rf "$tmp"
  return "$rc"
}

# ---------------------------------------------------------------------------
# GATE 10 — documentation/CORRECTIONS.md is APPEND-ONLY.
#
# WHY: a corrections ledger that can be edited is not a record, it is a draft. The
# failure mode is not malice — it is tidying: rewording an entry to read better,
# merging two entries, or dropping one that "was already fixed". Each of those makes
# the ledger agree with the present, which is exactly the property it must not have.
#
# WHAT IT CHECKS: every line of the LAST COMMITTED version must still be present, in
# order, in the working copy. `diff` is an LCS, so a moved or reworded line shows up as
# a deletion and fires — moving is not appending. Appending anywhere (including in the
# middle of the file, e.g. inserting a new entry between two existing ones) passes.
#
# NEGATIVE CONTROL: the self-test asserts BOTH halves — that a deleted line fires it and
# that a pure append does NOT. A gate with no negative control might simply always fail,
# and "it went red" would then be evidence of nothing.
gate_appendonly_head() {
  echo "== GATE 10a: CORRECTIONS.md is append-only vs HEAD =="
  local f="documentation/CORRECTIONS.md"
  if [ ! -f "$f" ]; then echo "  [skip] no $f"; return 0; fi
  if ! git cat-file -e "HEAD:$f" 2>/dev/null; then
    echo "  [ok] $f is not yet in HEAD — nothing committed to be append-only against"
    return 0
  fi
  local tmp gone
  tmp=$(mktemp) || return 1
  git show "HEAD:$f" > "$tmp" 2>/dev/null
  gone=$(diff "$tmp" "$f" | grep -c '^< ' || true)
  if [ "${gone:-0}" -eq 0 ]; then
    local added
    added=$(diff "$tmp" "$f" | grep -c '^> ' || true)
    echo "  [ok] no committed line removed or reworded ($added line(s) appended since HEAD)"
    rm -f "$tmp"; return 0
  fi
  echo "  [FAIL] $gone committed line(s) no longer present — CORRECTIONS.md is append-only."
  echo "         Removed or reworded (first 5):"
  diff "$tmp" "$f" | grep '^< ' | head -5 | cut -c1-140 | sed 's/^/           /'
  echo "         If an entry is wrong, APPEND an entry saying so. Both stay."
  rm -f "$tmp"
  return 1
}

# ---------------------------------------------------------------------------
# GATE 10b — the SAME invariant against every version that ever existed, not just HEAD.
#
# WHY (2026-08-02, item A7). 10a's baseline is `git show HEAD:<f>`, which makes
# "append-only" mean "append-only since the last commit". Two ordinary operations
# reset it:
#
#   (1) COMMIT THE REMOVAL. Delete an entry, commit. 10a compared against the
#       pre-commit HEAD and fired — but on the very next run HEAD *is* the truncated
#       version, the working copy matches it, and the gate returns to [ok] forever.
#       The ledger is permanently shorter and the gate attests that it is intact.
#       This is the likelier of the two; it needs no unusual git at all.
#   (2) REWRITE THE HISTORY. amend / rebase / squash moves the baseline along with
#       the content it dropped.
#
# WHAT THIS HALF CHECKS: every non-blank line of every baseline version must still be
# present in the working copy, counting multiplicity. Baselines are (i) every commit
# reachable from HEAD that touched the file, and (ii) every remote-tracking ref's
# version of it.
#
# WHY (ii) IS NOT REDUNDANT, and it is the half that answers case (2): after an amend
# or a rebase the pre-rewrite commit is NO LONGER AN ANCESTOR OF HEAD, so walking
# `git rev-list HEAD` cannot see it — a walk alone would close case (1) and leave
# case (2) exactly as open as before. `refs/remotes/*` is not moved by a local
# rewrite, so anything already PUBLISHED stays a baseline whatever happens to the
# local history.
#
# WHAT THIS CANNOT SEE, stated rather than implied:
#   - a line committed locally and then amended away BEFORE it was ever pushed. It is
#     unreachable from HEAD and was never on a remote, so no baseline holds it. The
#     reflog does, but the reflog is local, expires, and is empty in a fresh clone —
#     it is not an invariant anything can be gated on.
#   - ORDER and BLANK LINES. This half is a multiset containment check, so a
#     re-ordering passes it. 10a is the order-sensitive half (diff is an LCS); the two
#     are complementary and both run.
#
# COST (stated as a formula first, per the box-safety rule): B distinct blob versions
# x L lines, where B = commits-touching-the-file + remote-tracking-refs. Measured
# 2026-08-02: B = 5, L = 525.
gate_appendonly_history() {
  echo "== GATE 10b: CORRECTIONS.md has lost no line from ANY committed or published version =="
  local f="documentation/CORRECTIONS.md"
  if [ ! -f "$f" ]; then echo "  [skip] no $f"; return 0; fi
  local cur tmp bad=0 n=0 blob src seen=""
  cur=$(mktemp) || return 1
  tmp=$(mktemp) || { rm -f "$cur"; return 1; }
  grep -v '^[[:space:]]*$' "$f" | sort > "$cur"
  # Baselines, deduplicated by BLOB id: a commit that did not change the file, and a
  # remote ref pointing at a commit already walked, contribute nothing.
  for src in $( { git rev-list HEAD -- "$f" 2>/dev/null
                  git for-each-ref --format='%(refname)' refs/remotes 2>/dev/null; } ); do
    blob=$(git rev-parse --quiet --verify "$src:$f" 2>/dev/null) || continue
    [ -n "$blob" ] || continue
    case " $seen " in *" $blob "*) continue;; esac
    seen="$seen $blob"
    n=$((n+1))
    git cat-file -p "$blob" 2>/dev/null | grep -v '^[[:space:]]*$' | sort > "$tmp"
    local lost
    lost=$(comm -23 "$tmp" "$cur" | wc -l)
    if [ "${lost:-0}" -ne 0 ]; then
      echo "  [FAIL] $lost line(s) present in $src ($blob) are absent from the working copy."
      echo "         That version is committed or published; append-only means it can never lose a line."
      comm -23 "$tmp" "$cur" | head -5 | cut -c1-140 | sed 's/^/           /'
      echo "         If an entry is wrong, APPEND an entry saying so. Both stay."
      bad=1
    fi
  done
  if [ "$n" -eq 0 ]; then
    echo "  [ok] $f has no committed or published version yet — no baseline to lose a line from"
  elif [ "$bad" -eq 0 ]; then
    echo "  [ok] every line of all $n distinct historical/published version(s) survives in the working copy"
  fi
  rm -f "$cur" "$tmp"
  return $bad
}

gate_appendonly() {
  local rc=0
  gate_appendonly_head    || rc=1
  echo
  gate_appendonly_history || rc=1
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 11 — every REGISTERED retraction has an entry in the corrections ledger.
#
# WHY: RETRACTED_PHRASES.tsv (gate 3) stops a retracted wording from REAPPEARING. It
# says nothing about whether the retraction was ever RECORDED. Those are different
# failures, and the second is the quieter one: the corpus goes clean, the gate goes
# green, and no reader ever learns the claim was published in the first place.
#
# INDEPENDENCE (the reason this gate is worth having): it is registry-driven and does
# NOT consult scripts/corrections_inventory.sh's classifier. That classifier's C1 rule
# deliberately requires a hard retraction token and therefore deliberately under-fires;
# this gate is the instrument that catches what it misses. Two instruments that share a
# failure mode are one instrument.
#
# KEYING: each row is keyed by RP-<first 8 hex of sha256 of the retracted string>. The
# ledger cites the KEY, never the string — quoting the string in CORRECTIONS.md would
# reintroduce into the corpus the exact wording gate 3 exists to keep out. A key also
# cannot be faked by paraphrase, and a truncated quote cannot satisfy it.
gate_ledger() {
  echo "== GATE 11: registered retractions are recorded in CORRECTIONS.md =="
  local reg="documentation/RETRACTED_PHRASES.tsv" f="documentation/CORRECTIONS.md"
  if [ ! -f "$reg" ] || [ ! -f "$f" ]; then echo "  [skip] $reg or $f absent"; return 0; fi
  command -v sha256sum >/dev/null 2>&1 || { echo "  [skip] no sha256sum"; return 0; }
  local bad=0 n=0 key
  while IFS=$'\t' read -r phrase allow note; do
    case "$phrase" in ''|'#'*) continue;; esac
    n=$((n+1))
    key="RP-$(printf '%s' "$phrase" | sha256sum | cut -c1-8)"
    if grep -qF -- "$key" "$f"; then
      echo "  [ok] $key recorded"
    else
      echo "  [FAIL] $key has NO entry in $f"
      echo "         registry note: $note"
      echo "         Add an entry to CORRECTIONS.md citing $key (append only)."
      bad=1
    fi
  done < "$reg"
  [ "$bad" -eq 0 ] && echo "  [ok] all $n registered retraction(s) accounted for"
  return $bad
}

MODE="${1:-all}"
case "$MODE" in
  numbers) gate_numbers || RC=1 ;;
  cli)     gate_cli     || RC=1 ;;
  retract) gate_retract || RC=1 ;;
  retract-figures) gate_retract_figures || RC=1 ;;
  links)   gate_links_and_secrefs || RC=1 ;;
  secrefs) gate_secrefs || RC=1 ;;
  status)  gate_status  || RC=1 ;;
  figures) gate_figures || RC=1 ;;
  liveness) gate_liveness || RC=1 ;;
  banner)  gate_banner   || RC=1 ;;
  generated) gate_generated || RC=1 ;;
  appendonly) gate_appendonly || RC=1 ;;
  appendonly-head)    gate_appendonly_head    || RC=1 ;;
  appendonly-history) gate_appendonly_history || RC=1 ;;
  ledger)  gate_ledger  || RC=1 ;;
  all)     gate_numbers || RC=1; echo; gate_cli || RC=1; echo; gate_retract || RC=1
           echo; gate_retract_figures || RC=1
           echo; gate_links_and_secrefs || RC=1; echo; gate_status || RC=1
           echo; gate_figures || RC=1
           echo; gate_liveness || RC=1
           echo; gate_banner || RC=1
           echo; gate_appendonly || RC=1
           echo; gate_ledger || RC=1 ;;
  *) echo "usage: $0 {numbers|cli|retract|retract-figures|links|secrefs|status|figures|liveness|banner|appendonly|appendonly-head|appendonly-history|ledger|generated|all}"; exit 2 ;;
esac

echo
# State what the banner does NOT attest. GATES 1 and 5 are report-only (`return 0` /
# `sys.exit(0)`), so their [WARN]/[note] output never reaches RC; and GATE 8 is excluded
# from `all` by cost. A green banner that silently covers only 5 of 8 gates reads as more
# coverage than it has — the same over-attestation this suite exists to catch. (The
# self-test's own comment asserted this was "stated in the banner itself" before it was;
# written into the banner 2026-08-01 on same-day re-review.)
if [ "$RC" -ne 0 ]; then
  echo "DOC GATES: FINDINGS (see above)"
elif [ "$MODE" = all ]; then
  echo "DOC GATES: PASS  — hard gates only: 2, 3, 3b, 4 (incl. 4b), 6, 7, 9, 10 (a+b), 11. Gates 1 and 5 (incl. 5b) are REPORT-ONLY,"
  echo "                   so any [WARN]/[note] above is NOT covered by this verdict."
  echo "                   GATE 8 ('generated') is not in 'all' — run it separately."
elif [ "$MODE" = numbers ] || [ "$MODE" = status ]; then
  echo "DOC GATES: PASS  — NOTE: '$MODE' is a REPORT-ONLY gate and always exits 0."
  echo "                   Read its [WARN]/[note] lines above; this verdict does not."
else
  echo "DOC GATES: PASS  ($MODE)"
fi
exit $RC
