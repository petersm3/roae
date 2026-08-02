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
#   scripts/doc_gates.sh liveness   # frozen present-tense run status; runs named after unreached budgets
#   scripts/doc_gates.sh banner     # the TR banner is byte-identical across every report + index-aligned
#   scripts/doc_gates.sh appendonly # documentation/CORRECTIONS.md has lost no committed line
#   scripts/doc_gates.sh ledger     # every RETRACTED_PHRASES.tsv row is recorded in CORRECTIONS.md
#   scripts/doc_gates.sh generated  # generated artifacts still match their generator (~90s; NOT in `all`)
#   scripts/doc_gates.sh all        # run all ten cheap gates (1-7, 9, 10, 11); `generated` is separate by cost
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
allowed = {}       # legacy anchorless entries: exact "file:line", drift-prone by construction
anchored = {}      # file -> [(recorded_line, anchor)] — matched by content, immune to renumbering
if os.path.exists(allow):
    for l in open(allow, encoding='utf-8'):
        l = l.rstrip('\n')
        if not l.strip() or l.lstrip().startswith('#'): continue
        parts = l.split('\t')
        key = parts[0].strip()
        anc = parts[1].strip() if len(parts) > 1 and parts[1].strip() else None
        if anc is None:
            allowed[key] = None
        else:
            fpath, _, lno = key.rpartition(':')
            anchored.setdefault(fpath, []).append((lno, anc))
EST = r'estimate|estimated|Knuth|\bCI\b|confidence|Monte'
EX  = r'\bexact|\bproven|\bproved'
files = [p for p in subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True)
         .stdout.split()]
seen = 0; bad = 0; hits = set()   # hits: which registry rows actually occur in the corpus
for f in files:
    for ln, line in enumerate(open(f, encoding='utf-8', errors='replace').read().splitlines(), 1):
        for val, want in rows:
            if re.fullmatch(r'[\d.]+', val) and ',' not in val:
                if not re.search(re.escape(val) + r'\s*[×x]\s*10', line): continue
            elif val not in line:
                continue
            seen += 1
            hits.add(val)
            etoks = sorted(set(t.lower() for t in re.findall(EST, line, re.I)))
            xtoks = sorted(set(t.lower() for t in re.findall(EX, line, re.I)))
            he, hx = bool(etoks), bool(xtoks)
            conflict = (want == 'exact' and he and not hx) or (want == 'estimate' and hx and not he)
            if conflict:
                if f"{f}:{ln}" in allowed: continue
                if any(a in line for _, a in anchored.get(f, ())): continue
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
    for lno, anc in entries:
        hits = [i for i, l in enumerate(text, 1) if anc in l]
        if not hits:
            print(f"  [note] allowlist: {fpath}:{lno} anchor no longer appears in the file — prune it")
            print(f"         anchor: {anc[:120]}")
        elif len(hits) > 1:
            print(f"  [note] allowlist: {fpath}:{lno} anchor matches {len(hits)} lines {hits[:6]} — "
                  "suppression is broader than one reviewed sentence; make it more specific")
        elif str(hits[0]) != str(lno):
            print(f"  [note] allowlist: {fpath}:{lno} anchor now sits at :{hits[0]} — "
                  "suppression still correct (matched by content); update the recorded line")
for key in sorted(allowed):
    print(f"  [note] allowlist: {key} has no content anchor — it is matched by line number alone "
          "and will drift silently; add a TAB-separated anchor")
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

  assert_fires "GATE 3 retracted phrasing" documentation/GUIDE.md retract \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe ordering has a hard floor k>=13 by construction.\n')"

  assert_fires "GATE 4 internal links" documentation/GUIDE.md links \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nSee [the missing doc](NO_SUCH_FILE_XYZ.md).\n')"

  # GATE 4b, in the EXACT shape of its motivating defect: the link target resolves
  # (CRITIQUE.md exists, so phase 1 stays green) and only the section half is dead.
  # If this assertion ever passes-through, the extension has stopped seeing the one
  # class it was written for. The quoted form §\"...\" was verified by the same
  # method when the gate was written.
  assert_fires "GATE 4b dangling section ref" documentation/GUIDE.md links \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nPriced as data ([CRITIQUE.md](CRITIQUE.md) Q7).\n')"

  assert_fires "GATE 6 figure generators" viz/README.md figures \
"import glob,sys
c=[f for f in glob.glob('viz/*.py')]
sys.exit(1) if not c else None
s=open(c[0]).read()
open(c[0],'w').write(s+'\n# hard floor k>=13\n')"

  assert_fires "GATE 7 frozen run status" documentation/GUIDE.md liveness \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe ladder build is in flight and the log is 3,666 lines and growing.\n')"

  assert_fires "GATE 7 unreached budget" documentation/GUIDE.md liveness \
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
  assert_fires "GATE 10 append-only (committed line deleted)" documentation/CORRECTIONS.md appendonly \
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

  # GATE 11: a registry row with no ledger entry must fire it. Injected as a NEW registry
  # row rather than by deleting a ledger entry, because deletion would fire GATE 10 and
  # the assertion would pass for the wrong reason — the two gates must be shown to be
  # independent, not merely both red.
  assert_fires "GATE 11 ledger completeness (unrecorded retraction)" documentation/RETRACTED_PHRASES.tsv ledger \
"open('documentation/RETRACTED_PHRASES.tsv','a').write(
 'a synthetic phrasing that was never published'+chr(9)+'__none__'+chr(9)+'Self-test row: no ledger entry exists for it, so GATE 11 must fail.'+chr(10))"

  # GATE 2 (CLI drift) and GATE 5 (epistemic status) are not mutation-tested here:
  # both would require editing solve.py / a canonical quantity, and a bad revert
  # there is far more costly than the assurance is worth. They are covered by
  # having FIRED in anger during the 2026-07/08 sweeps (13 undocumented flags;
  # 99 canonical-quantity occurrences checked). Stated rather than silently
  # omitted — a self-test that hides its own coverage gap is the defect it tests for.
  echo "  [note] GATE 2 + GATE 5 not mutation-tested (would mutate solve.py / canonical"
  echo "         quantities); both have fired in anger during earlier sweeps."

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
# Cost ~45s, so this is NOT part of `all`. Run it before publishing.
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
  local tmp rc=0
  tmp=$(mktemp -d) || return 1
  command -v python3 >/dev/null 2>&1 || { echo "  [skip] no python3"; rm -rf "$tmp"; return 0; }

  # `--markdown` is run WITHOUT `--all` and from inside $tmp, because that is what the
  # generator actually does: roae.py's main() short-circuits on args.markdown (returns
  # before the --all dispatch), and export_markdown() opens report.md in the CWD.
  # Spelling it "--all --markdown > file" is the recipe that corrupted example/ once
  # already; the gate should not model it. (Function names, not line numbers, on
  # purpose — a recorded line number is the thing that drifts, cf. the GATE 5 allowlist.)
  echo "  regenerating (~90s, unseeded): --all to stdout, then --markdown into a temp dir"
  if ! timeout 300 python3 roae.py --all > "$tmp/fresh.txt" 2>/dev/null; then
    echo "  [FAIL] the generator itself did not run cleanly"; rm -rf "$tmp"; return 1
  fi
  ( cd "$tmp" && timeout 300 python3 "$OLDPWD/roae.py" --markdown >/dev/null 2>&1 )
  [ -f "$tmp/report.md" ] || { echo "  [skip] --markdown produced no report.md"; rm -rf "$tmp"; return 0; }

  _norm() { sed 's/[0-9]//g; s/[[:space:]]\+/ /g' "$1" | grep -v '^ *$' | sort; }
  # BOTH DIRECTIONS. The first version compared one way only (`comm -13`: lines the
  # ARTIFACT has that the generator does not), so a pure DELETION from a shipped
  # artifact passed -- and passed while printing "matches ... exactly", which is the
  # same over-attestation this suite exists to catch. Demonstrated 2026-08-01 by
  # deleting the nuclear-attractor line from example/report.txt: the gate said [ok].
  # Substitutions were caught only because they leave an added line behind as well.
  _cmp() {   # <artifact> <reference> <label>
    [ -f "$1" ] || { echo "  [skip] $1 absent"; return 0; }
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
  _cmp example/report.txt "$tmp/fresh.txt"  "roae.py --all"      || rc=1
  _cmp example/report.md  "$tmp/report.md"  "roae.py --markdown" || rc=1
  _cmp example/README.md  "$tmp/report.md"  "roae.py --markdown" || rc=1
  rm -rf "$tmp"
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
gate_appendonly() {
  echo "== GATE 10: CORRECTIONS.md is append-only =="
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
  links)   gate_links   || RC=1 ;;
  status)  gate_status  || RC=1 ;;
  figures) gate_figures || RC=1 ;;
  liveness) gate_liveness || RC=1 ;;
  banner)  gate_banner   || RC=1 ;;
  generated) gate_generated || RC=1 ;;
  appendonly) gate_appendonly || RC=1 ;;
  ledger)  gate_ledger  || RC=1 ;;
  all)     gate_numbers || RC=1; echo; gate_cli || RC=1; echo; gate_retract || RC=1
           echo; gate_links || RC=1; echo; gate_status || RC=1
           echo; gate_figures || RC=1
           echo; gate_liveness || RC=1
           echo; gate_banner || RC=1
           echo; gate_appendonly || RC=1
           echo; gate_ledger || RC=1 ;;
  *) echo "usage: $0 {numbers|cli|retract|links|status|figures|liveness|banner|appendonly|ledger|generated|all}"; exit 2 ;;
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
  echo "DOC GATES: PASS  — hard gates only: 2, 3, 4 (incl. 4b), 6, 7, 9, 10, 11. Gates 1 and 5 are REPORT-ONLY,"
  echo "                   so any [WARN]/[note] above is NOT covered by this verdict."
  echo "                   GATE 8 ('generated') is not in 'all' — run it separately."
elif [ "$MODE" = numbers ] || [ "$MODE" = status ]; then
  echo "DOC GATES: PASS  — NOTE: '$MODE' is a REPORT-ONLY gate and always exits 0."
  echo "                   Read its [WARN]/[note] lines above; this verdict does not."
else
  echo "DOC GATES: PASS  ($MODE)"
fi
exit $RC
