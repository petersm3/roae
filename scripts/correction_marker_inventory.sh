#!/usr/bin/env bash
# correction_marker_inventory.sh — step 1 of the inline-correction hygiene work: every inline
# correction MARKER in the public markdown, and whether a doc gate depends on it.
#
# WHAT IT IS
#   The inline markers (`⚠ **[CORRECTED …]**`, `[WITHDRAWN …]`, `[RETRACTED …]`, `[SUPERSEDED …]`,
#   "now reads") are to move into documentation/CORRECTIONS.md so that each document reads as its
#   corrected self. A marker does one of three jobs, and only the first is safe to move as it
#   stands:
#     class 1  redundant     — the current text already reads correctly without it;
#     class 2  load-bearing  — without it a reader could re-derive the withdrawn claim from text
#                              that was not changed; the surrounding text must be rewritten first;
#     class 3  gate-anchored — a doc gate's verdict depends on it, so the gate must be re-anchored
#                              (and shown red on a planted violation) before the marker moves.
#   This script decides class 3 MECHANICALLY and records which gate leg it is. Classes 1 and 2
#   are an editorial judgement; a row nobody has reviewed yet says `1|2` and `unreviewed`, and a
#   reviewed row carries its verdict from the REVIEWED table below, keyed on the line's content.
#
# HOW CLASS 3 IS DECIDED (ablation, not a keyword list)
#   Several gates treat marker vocabulary as "this is narration, not a claim" and exempt the
#   line or paragraph (GATE 27's MARK, the NARR/CORRM patterns of later gates, the `[CORRECTED …]`
#   span strip of the derived-figure gates). Reading ~50 such patterns and guessing which marker
#   each one needs is the error-prone route. Instead the script MEASURES it: it copies the tree
#   twice, deletes every marker span in one copy (newlines kept, so no line moves), runs
#   `scripts/doc_gates.sh` (all) and `scripts/citation_line_gate.sh --all-files --all-targets` in
#   both copies, and diffs the output. A new output line that cites `FILE.md:N` is attributed to
#   every marker whose span covers line N or whose block (the table row for a table line, else the
#   blank-line paragraph) contains N. The gate section the new line appears under is the leg.
#   A changed line that cites no line is handled by shape: the citation gate's `A.md->B[key]` pin
#   form is tied to the marker in A whose block holds `key`; a FINDING ([FAIL]/[note]/…) naming a
#   file is tied to the markers whose block holds a string the finding quotes, else to every marker
#   in that file (leg suffixed `(file)`); a COUNT line ([ok]/[info]/[cite] …) means the gate's
#   population moved, and becomes a `population` row (class `3?`, per gate and file), because no
#   single marker can be named from it. Those rows are what makes the verdict INCOMPLETE.
#   GATE 13 (a TR body edit needs a revision row; report-only) changes on ANY edit and is recorded
#   as one `any-edit` row, not as evidence against any marker.
#   The ablation is conservative in one direction: all markers are removed at once, so a gate that
#   only fails once EVERY marker is gone is attributed to each marker in the cited block, never
#   missed. It deletes the whole span, including any withdrawn wording quoted inside it, which is
#   what moving the marker into the ledger would do.
#
# WHAT IS A MARKER, AND WHAT IS NOT
#   kind=marker     a bracketed `[CORRECTED`, `[CORRECTION <date>`, `[WITHDRAWN`, `[RETRACTED`,
#                   `[SUPERSEDED` span. Ablated.
#   kind=narration  the prose phrase "now reads". Ablated by deleting the phrase.
#   kind=ledger-link a `[CORRECTIONS.md](…)` / `[CORRECTIONS CX-NN](…)` / `[RETRACTED_PHRASES.tsv](…)`
#                   LINK (any bracket that is a link's text). Not a marker: it is the back-pointer
#                   form this work moves markers TO. Counted, never ablated.
#                   (A plain `grep '\[CORRECTION'` counts these as markers; most `[CORRECTION`
#                   hits in this corpus are these links.)
#   kind=changelog  a revision-history row (`| vN.M |`). The report's own changelog, read by
#                   GATE 12/13. Counted, never ablated, never moved.
#   CORRECTIONS.md and HISTORY.md are excluded: both are append-only ledgers.
#
# USAGE (the ablation runs the doc gates twice, ~3 minutes on a 16-core box: NOT on a 2-core one)
#   scripts/correction_marker_inventory.sh            # write documentation/CORRECTION_MARKER_INVENTORY.tsv
#   scripts/correction_marker_inventory.sh --stdout   # the same TSV on stdout
#   scripts/correction_marker_inventory.sh --list     # enumeration only, no gates run (class column `-`)
#   scripts/correction_marker_inventory.sh --selftest # span/kind known answers on synthetic text
#   CMI_KEEP_LOGS=DIR …                               # also keep the two gate logs in DIR, and
#   scripts/correction_marker_inventory.sh --attribute BASE.log ABL.log   # re-attribute them
# Verdict: one whole line CORRECTION_MARKER_INVENTORY=<COMPLETE|INCOMPLETE|ERROR> on stderr.
#   COMPLETE   every changed gate line was attributed to a marker line;
#   INCOMPLETE some gate's population moved with no marker nameable (listed; `population` rows);
#              the TSV is still written;
#   ERROR      nothing trustworthy was measured (no markers found, a gate run failed to start,
#              or the positive control below failed); nothing is written.
# POSITIVE CONTROL: GATE 27 exempts a withdrawn figure only when its block carries a marker, and
#   this corpus has WITHDRAWN markers beside registered withdrawn figures. If the ablation produces
#   no GATE 27 attribution the detector is blind, and the run is an ERROR, not an empty class 3.
#
# COLUMNS: file  line  kind  token  class  legs  review  line_sha
#   line_sha is the first 12 hex of sha256 of the line's text: it keys the REVIEWED table and
#   tells a reader whether the line still says what was classified. No line text is copied here:
#   quoting a withdrawn phrase into a data file would restate it.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "CORRECTION_MARKER_INVENTORY=ERROR cd" >&2; exit 2; }
OUT="documentation/CORRECTION_MARKER_INVENTORY.tsv"
MODE="${1:-write}"

core() {  # core <mode> [args...] — the Python half; modes: list | ablate DIR | attribute BASE ABL
python3 - "$@" <<'PY'
import hashlib, json, os, re, subprocess, sys

HIT = re.compile(r'\[CORRECTED|\[CORRECTION|now reads|\[WITHDRAWN|\[RETRACTED|\[SUPERSEDED')
CHANGELOG = re.compile(r'^\| *[vV][0-9]')
EXCLUDE = re.compile(r'(^|/)(CORRECTIONS|HISTORY)\.md$')

# REVIEWED — class 1/2 verdicts, keyed (file, line_sha). A key that no longer matches a line is
# reported on stderr (the line changed, so its verdict must be re-read), never silently applied.
# Values are (class, review) and the review is one token (no spaces, no tab): what was decided.
REVIEWED = {
    # tranche 1 (2026-09-26, the f11halfb evidence family). The marker at
    # reports/evidence/f11halfb/README.md:21@5a3b2917 was class 1 and has moved to the ledger, so it
    # is no longer a row here.
    ('reports/evidence/f11halfb/RESULTS.md', 'fd712baff659'):
        ('2', 'stays:the-quoted-recommended-wording-above-it-is-kept-as-TR-2-published-it-and-is-still-inaccurate'),
    ('documentation/F1C5_LAYER_FORMAT.md', '801779b51687'):
        ('1', 'reviewed:text-already-reads-3.29-TB-measured;moving-it-means-rewrapping-lines-105-112'),
}

def md_files():
    out = subprocess.run(['git', 'ls-files', '-z', '--', '*.md'], capture_output=True, check=True).stdout
    return sorted(f for f in out.decode().split('\0') if f and not EXCLUDE.search(f))

def lsha(s):
    return hashlib.sha256(s.encode()).hexdigest()[:12]

def match_bracket(text, i):
    """index just past the `]` matching the `[` at i, bounded by the paragraph (blank line)."""
    depth = 0; j = i; n = len(text)
    while j < n:
        c = text[j]
        if c == '[': depth += 1
        elif c == ']':
            depth -= 1
            if depth == 0: return j + 1, True
        elif c == '\n' and re.match(r'\n[ \t]*(\n|$)', text[j:j+80]):
            return j, False
        j += 1
    return n, False

def spans(text):
    """yield (start, end, kind, token, closed, token_pos) for every hit in text."""
    for m in HIT.finditer(text):
        tok = m.group(0).lstrip('[')
        s = m.start()
        ls = text.rfind('\n', 0, s) + 1
        le = text.find('\n', s); le = len(text) if le < 0 else le
        if CHANGELOG.match(text[ls:le]):
            yield (s, s, 'changelog', tok, True, s); continue
        if tok == 'now reads':
            yield (s, m.end(), 'narration', tok, True, s); continue
        e, closed = match_bracket(text, s)
        if closed and text[e:e+1] == '(':   # a markdown LINK whose text starts with the word
            yield (s, s, 'ledger-link', tok, True, s); continue
        # widen over the decoration around the bracket: `⚠ **[` … `]**`
        b = s
        pre = re.search(r'(⚠️? ?)?\*\*$', text[max(ls, s-8):s])
        if pre: b = s - len(pre.group(0))
        if closed and text[e:e+2] == '**': e += 2
        yield (b, e, 'marker', tok, closed, s)

def line_of(text, pos):
    return text.count('\n', 0, pos) + 1

def blocks(lines):
    """line -> (first,last) of its block: a table row alone, else its blank-line paragraph."""
    blk = {}; n = len(lines); i = 0
    while i < n:
        if not lines[i].strip(): i += 1; continue
        if lines[i].lstrip().startswith('|'):
            blk[i+1] = (i+1, i+1); i += 1; continue
        j = i
        while j + 1 < n and lines[j+1].strip() and not lines[j+1].lstrip().startswith('|'): j += 1
        for k in range(i, j+1): blk[k+1] = (i+1, j+1)
        i = j + 1
    return blk

def inventory():
    rows = []
    for f in md_files():
        try: text = open(f, encoding='utf-8').read()
        except (OSError, UnicodeDecodeError): continue
        lines = text.split('\n')
        seen = {}
        for (b, e, kind, tok, closed, tp) in spans(text):
            ln = line_of(text, tp)          # the line the TOKEN sits on (a decoration may start earlier)
            el = line_of(text, e - 1) if e > tp else ln
            key = (ln, kind, tok)
            if key in seen: continue
            seen[key] = 1
            rows.append(dict(file=f, line=ln, end=el, kind=kind, token=tok, closed=closed,
                             b=b, e=e, sha=lsha(lines[ln-1])))
    return rows

def ablate(root):
    """delete every marker/narration span in the copy at root, newlines kept."""
    n = 0
    for f in md_files():
        p = os.path.join(root, f)
        text = open(p, encoding='utf-8').read()
        cut = [(b, e) for (b, e, kind, tok, closed, tp) in spans(text) if kind in ('marker', 'narration') and e > b]
        if not cut: continue
        out = []; last = 0
        for (b, e) in sorted(cut):
            if b < last: b = last
            if e <= last: continue
            out.append(text[last:b]); out.append(re.sub(r'[^\n]', '', text[b:e])); last = e
        out.append(text[last:])
        new = ''.join(out)
        if new.count('\n') != text.count('\n'): raise SystemExit(f'correction_marker_inventory: blanking changed the line count of {f} (line citations would shift)')
        open(p, 'w', encoding='utf-8').write(new); n += len(cut)
    return n

def sections(path):
    """[(section header, line)] for a gate log; header = the last `== … ==` line above."""
    res = []; cur = '(preamble)'
    for l in open(path, encoding='utf-8', errors='replace').read().split('\n'):
        if re.match(r'^== .* ==$', l):
            cur = l.strip()
        res.append((cur, l))
    return res

CITE = re.compile(r'([A-Za-z0-9_./-]+\.md):([0-9]+)')

CITE2 = re.compile(r'(?:^|\s):([0-9]+) \[([A-Za-z0-9_./-]+\.md)\]')   # citation gate's ":N [path]" form
MDPATH = re.compile(r'[A-Za-z0-9_./-]+\.md\b')
ARROW = re.compile(r'([A-Za-z0-9_./-]+\.md)->[A-Za-z0-9_./-]+\[([^\]]+)\]')
QUOTE = re.compile(r'"([^"]{6,})"')
# Legs whose output changes on ANY edit to a file of their population, whatever the edit: a TR body
# edit needs a revision row (GATE 13, report-only), and the citation gate's leg-A summary counts
# edited files. They are requirements every tranche meets, not evidence that a marker is anchored.
ANY_EDIT = ('GATE 13',)

def attribute(base, abl):
    from collections import Counter
    rows = inventory()
    bl = Counter(l for (_, l) in sections(base))
    by = {}
    for r in rows: by.setdefault(r['file'], []).append(r)
    blk = {}; src = {}
    changed = {}; attributed = {}; anyedit = set(); pop = set()
    def resolve(f):
        if f in by: return f
        g = [k for k in by if k.endswith('/' + f)]
        return g[0] if len(g) == 1 else None
    def load(f):
        if f not in src:
            src[f] = open(f, encoding='utf-8').read().split('\n'); blk[f] = blocks(src[f])
    linehit = set(); deferred = []
    def tag(r, leg, sec):
        r.setdefault('legs', set()).add(leg); attributed[sec] = 1
        if not leg.endswith('(file)'): linehit.add((sec, r['file']))
    for (sec, l) in sections(abl):
        if bl[l] > 0: bl[l] -= 1; continue
        leg = sec.strip('= ').split(':')[0]
        if leg in ANY_EDIT: anyedit.add(sec); continue
        changed[sec] = changed.get(sec, 0) + 1
        cites = [(f, n) for (f, n) in CITE.findall(l)] + [(f, n) for (n, f) in CITE2.findall(l)]
        hit = False
        for (f, n) in cites:
            f = resolve(f)
            if f is None: continue
            n = int(n); load(f); hit = True
            lo, hi = blk[f].get(n, (n, n))
            for r in by[f]:
                if r['kind'] not in ('marker', 'narration'): continue
                if r['line'] <= n <= r['end'] or (lo <= r['line'] <= hi) or (r['line'] <= hi and r['end'] >= lo):
                    tag(r, leg, sec)
        if hit: continue
        # the citation gate's pin form `CITING.md->TARGET[key]`: the CITING line's text changed, so
        # the marker in CITING whose block holds `key` is the one the pin rests on.
        for (f, key) in ARROW.findall(l):
            f = resolve(f)
            if f is None: continue
            load(f); hit = True
            ms = [r for r in by[f] if r['kind'] in ('marker', 'narration')]
            near = [r for r in ms if key in '\n'.join(src[f][blk[f].get(r['line'], (r['line'], r['end']))[0]-1:max(blk[f].get(r['line'], (0, r['end']))[1], r['end'])])]
            for r in (near or ms): tag(r, leg if near else leg + '(file)', sec)
        if hit: continue
        # a COUNT line ([ok]/[info]/[cite]/[measured]/scanned …) naming no finding: the gate's
        # population moved. Recorded per section (and file, when one is named), not per marker.
        if not re.search(r'\[(FAIL|note|WARN|NEW|REPIN|inhunk)\]', l):
            for f in (set(MDPATH.findall(l)) or {'-'}):
                pop.add((sec, resolve(f) or '-'))
            continue
        # a FINDING with no line cited: file-level (an allowlist anchor that matched nothing, a
        # digest, a sum over a file). Narrowed by any quoted anchor the line carries; else the file.
        deferred.append((sec, leg, l))
    # second pass, so a file-level finding can see the line-level ones of its own section: a finding
    # that names a file the same section already tied to a marker by line (the citation gate's
    # `[inhunk]`/`[REPIN]` lines, then its `leg A2` summary naming the same pair) is explained by
    # them, and is not spread over every other marker in that file.
    for (sec, leg, l) in deferred:
        for f in set(MDPATH.findall(l)):
            f = resolve(f)
            if f is None or (sec, f) in linehit: continue
            load(f)
            ms = [r for r in by[f] if r['kind'] in ('marker', 'narration')]
            qs = QUOTE.findall(l)
            near = []
            for r in ms:
                lo, hi = blk[f].get(r['line'], (r['line'], r['end']))
                t = '\n'.join(src[f][lo-1:max(hi, r['end'])])
                if any(q in t for q in qs): near.append(r)
            for r in (near or ms): tag(r, leg if near else leg + '(file)', sec)
    unattr = sorted(s for s in changed if s not in attributed)
    pop |= {(s, '-') for s in unattr if not any(p[0] == s for p in pop)}
    return rows, unattr, sorted(anyedit), sorted(pop)

def emit(rows, measured):
    print('\t'.join(['file', 'line', 'kind', 'token', 'class', 'legs', 'review', 'line_sha']))
    used = set()
    for r in sorted(rows, key=lambda r: (r['file'], r['line'], r['kind'], r['token'])):
        legs = ','.join(sorted(r.get('legs', ())))
        k = (r['file'], r['sha'])
        if r['kind'] == 'ledger-link': cls, rev = 'n/a', 'not-a-marker'
        elif r['kind'] == 'changelog': cls, rev = 'keep', 'revision-row'
        elif not measured: cls, rev = '-', 'not-measured'
        elif legs: cls, rev = '3', 'gate-anchored'
        elif k in REVIEWED: cls, rev = REVIEWED[k]; used.add(k)
        else: cls, rev = '1|2', 'unreviewed'
        if r['kind'] == 'marker' and not r['closed']: rev += ';span-unclosed'
        print('\t'.join([r['file'], str(r['line']), r['kind'], r['token'], cls, legs or '-', rev, r['sha']]))
    for k in sorted(set(REVIEWED) - used):
        print('REVIEWED key matches no unanchored marker line (re-read it): %s %s' % k, file=sys.stderr)

mode = sys.argv[1]
if mode == 'list':
    emit(inventory(), False)
elif mode == 'ablate':
    os.chdir(sys.argv[2]); print(ablate('.'))
elif mode == 'attribute':
    rows, unattr, anyedit, pop = attribute(sys.argv[2], sys.argv[3])
    g27 = sum(1 for r in rows if any(x.startswith('GATE 27') for x in r.get('legs', ())))
    emit(rows, True)
    # a changed gate section no marker line could be tied to: the gate's POPULATION moved (a count
    # it prints fell or rose). It is a row of the table, class `3?`, so it cannot be overlooked.
    for (s, f) in pop:
        print('\t'.join([f, '-', 'population', '-', '3?', s.strip('= ').split(':')[0], 'count-changed', '-']))
    for s in anyedit:
        print('\t'.join(['-', '-', 'any-edit', '-', 'n/a', s.strip('= ').split(':')[0], 'fires-on-any-edit', '-']))
    for (s, f) in pop: print('UNATTRIBUTED\t%s\t%s' % (s, f), file=sys.stderr)
    print('G27=%d UNATTR=%d MARKERS=%d' % (g27, len(pop), sum(1 for r in rows if r['kind'] in ('marker', 'narration'))), file=sys.stderr)
elif mode == 'selftest':
    ok = True
    def chk(name, got, want):
        global ok
        print(('  [ok]   ' if got == want else '  [FAIL] ') + name + ' -> %r' % (got,) + ('' if got == want else ' want %r' % (want,)))
        ok = ok and got == want
    t = 'A claim. ⚠ **[CORRECTED 2026-09-01 — this read "x [n]" before.]** More.\n'
    s = list(spans(t))
    chk('marker span covers decoration and nested brackets', t[s[0][0]:s[0][1]], '⚠ **[CORRECTED 2026-09-01 — this read "x [n]" before.]**')
    t = 'See [CORRECTIONS.md](CORRECTIONS.md), [CORRECTIONS CX-25](x/CORRECTIONS.md), [RETRACTED_PHRASES.tsv](R.tsv).\n'
    chk('ledger/registry links are not markers', [x[2] for x in spans(t)], ['ledger-link'] * 3)
    t = '| v1.2 | 2026-09-01 | [CORRECTED x] |\n'
    chk('a revision row is changelog', [x[2] for x in spans(t)], ['changelog'])
    t = 'Para ⚠ **[WITHDRAWN 2026-08-24 — no close\n\nNext para.\n'
    s = list(spans(t))
    chk('an unclosed span stops at the paragraph', (t[s[0][0]:s[0][1]].count('Next'), s[0][4]), (0, False))
    t = 'one ⚠ **[CORRECTED 2026 — a\nb]** two\nthe text now reads y\n'
    import tempfile
    d = tempfile.mkdtemp(); os.chdir(d)
    subprocess.run(['git', 'init', '-q'], check=True)
    open('A.md', 'w').write(t); open('HISTORY.md', 'w').write(t)
    subprocess.run(['git', 'add', 'A.md', 'HISTORY.md'], check=True)
    chk('inventory lines: marker on its token line, narration', [(r['line'], r['end'], r['kind']) for r in inventory()], [(1, 2, 'marker'), (3, 3, 'narration')])
    ablate('.')
    chk('ablation keeps every newline and deletes span + phrase', open('A.md').read(), 'one \n two\nthe text  y\n')
    chk('HISTORY.md is never ablated', open('HISTORY.md').read(), t)
    print('CORRECTION_MARKER_INVENTORY_SELFTEST=' + ('PASS' if ok else 'FAIL'))
PY
}

case "$MODE" in
  --selftest) core selftest; exit $? ;;
  --list)     core list; exit $? ;;
  --attribute) core attribute "$2" "$3"; exit $? ;;   # re-attribute two kept gate logs (CMI_KEEP_LOGS)
  write|--stdout) ;;
  *) echo "usage: $0 [--stdout|--list|--selftest]" >&2; exit 2 ;;
esac

W=$(mktemp -d) || { echo "CORRECTION_MARKER_INVENTORY=ERROR mktemp" >&2; exit 2; }
trap 'rm -rf "$W"' EXIT
# Two identical copies of the working tree (tracked + untracked-but-not-ignored, with .git so the
# gates that read HEAD see the same HEAD), so the only difference between the two runs is the ablation.
for c in base abl; do
  mkdir -p "$W/$c" && cp -a .git "$W/$c/.git" \
    && git ls-files -z --cached --others --exclude-standard | (cd . && xargs -0 cp --parents -a -t "$W/$c" 2>/dev/null) \
    || { echo "CORRECTION_MARKER_INVENTORY=ERROR copy-failed $c" >&2; exit 2; }
done
N=$(core ablate "$W/abl") || { echo "CORRECTION_MARKER_INVENTORY=ERROR ablate-failed" >&2; exit 2; }
[ "${N:-0}" -gt 0 ] || { echo "CORRECTION_MARKER_INVENTORY=ERROR no-markers-ablated" >&2; exit 2; }
for c in base abl; do
  ( cd "$W/$c" && { bash scripts/doc_gates.sh; echo '== CITATION LINE GATE =='; bash scripts/citation_line_gate.sh --all-files --all-targets; } > "$W/$c.log" 2>&1 ) &
done
wait
for c in base abl; do
  grep -q '^== GATE 1:' "$W/$c.log" || { echo "CORRECTION_MARKER_INVENTORY=ERROR gate-run-empty $c" >&2; exit 2; }
done
core attribute "$W/base.log" "$W/abl.log" > "$W/out.tsv" 2> "$W/err" || { cat "$W/err" >&2; echo "CORRECTION_MARKER_INVENTORY=ERROR attribute-failed" >&2; exit 2; }
cat "$W/err" >&2
[ -n "${CMI_KEEP_LOGS:-}" ] && cp "$W/base.log" "$W/abl.log" "$CMI_KEEP_LOGS/"   # debugging aid: keep both gate logs
G27=$(sed -n 's/^G27=\([0-9]*\) .*/\1/p' "$W/err")
if [ "${G27:-0}" -eq 0 ]; then
  echo "CORRECTION_MARKER_INVENTORY=ERROR positive-control: no GATE 27 attribution, the ablation saw nothing" >&2; exit 2
fi
if [ "$MODE" = --stdout ]; then cat "$W/out.tsv"; else cp "$W/out.tsv" "$OUT"; echo "-> $OUT ($(($(wc -l < "$OUT") - 1)) rows)" >&2; fi
if grep -q '^UNATTRIBUTED' "$W/err"; then
  echo "CORRECTION_MARKER_INVENTORY=INCOMPLETE" >&2
else
  echo "CORRECTION_MARKER_INVENTORY=COMPLETE" >&2
fi
