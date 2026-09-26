#!/usr/bin/env bash
# history_index.sh — generate and check documentation/HISTORY_INDEX.md, a chronological index of
# the dated H2 sections of documentation/HISTORY.md. Q-686, 2026-09-26.
# Claude (Opus 5.5), developed with AI assistance (Claude, Anthropic).
#
# WHY. HISTORY.md is APPEND-ONLY: a section stays where it was first written and is never moved or
# reworded. Some sections were written after later-dated ones (a recovered entry appended at the
# end, a date range whose first day precedes the section above it), so reading the file top to
# bottom is not reading it in date order, and nothing in the file says so. Moving the sections
# would break append-only. This index leaves the file alone and gives the date order beside it.
#
# HOW DATES ARE READ. Only H2 headings (`## `) are indexed. Each is placed in the first tier that
# matches, in this order:
#   iso      the grammar of scripts/history_currency_gate.sh, read OUT OF THAT SCRIPT at run time
#            (its `re.finditer(r'...'` pattern). `## 2026-09-07`, `## 2026-07-04/05` (bare DD, same
#            month), `## 2026-08-08/08-30` (MM-DD), each optionally after one leading emoji/symbol token
#            (`## 🛑 2026-08-16: ...`, since 2026-09-26). One grammar, one copy: if that gate's pattern
#            changes, this index changes with it, and if the pattern cannot be found this script
#            says ERROR instead of guessing.
#   prose    a month name and day at the start of the heading (after any leading emoji or symbol),
#            with the first four-digit year later in it: `## April 16-17, 2026`,
#            `## April 30 – May 2, 2026 PDT (...)`. The date is the FIRST day named.
#   embedded an ISO date anywhere else in the heading: `## Infrastructure (2026-04-22)`. The first
#            one is used. (`## 🛑 2026-08-16: ...` was read here until 2026-09-26, when the currency
#            gate's grammar learned the leading symbol; it is `iso` now.)
#   undated  none of the above (`## Missteps and corrections (summary)`, the Prelude). Listed in
#            file order in their own table, never placed on the date line.
# Dates are as written. Headings mix PDT, PT and UTC; they are not converted. A range sorts by its
# first day. Ties keep file order.
#
# ANCHORS. Each row links to its section by the GitHub heading slug, computed with the same rule
# and the same duplicate numbering (-1, -2 over EVERY heading level, in file order) as GATE 4 of
# scripts/doc_gates.sh (`links`), so that gate checks every link this index writes.
#
# USAGE
#   bash scripts/history_index.sh              write documentation/HISTORY_INDEX.md
#   bash scripts/history_index.sh --stdout     print it, write nothing
#   bash scripts/history_index.sh --check      compare the committed index with a fresh one
#   bash scripts/history_index.sh --selftest   run the check against mutated copies (below)
#   Options for --check/--stdout/write: --history FILE, --index FILE, --currency-gate FILE
#   (the defaults are the tracked files; the options exist for the self-test).
#
# VERDICTS, whole lines, `grep -qx`-able:
#   HISTORY_INDEX=CURRENT     rc 0  the committed index is byte-identical to a fresh one
#   HISTORY_INDEX=STALE       rc 1  it differs (first differing line printed): regenerate it
#   HISTORY_INDEX=ERROR       rc 2  nothing was compared (unreadable input, no grammar, 0 headings)
#   HISTORY_INDEX_SELFTEST=PASS|FAIL   from --selftest; rc 0 / 1
#
# SELF-TEST (--selftest). On temporary copies, never the tracked files: the unmodified copies must
# read CURRENT (positive control); then each mutant must read the stated verdict —
#   M1 a new ISO-dated section appended to HISTORY.md, index not regenerated    -> STALE
#   M2 one row deleted from the index                                           -> STALE
#   M3 two adjacent rows of the index swapped                                   -> STALE
#   M4 the currency gate's heading pattern removed                              -> ERROR
#   M5 HISTORY.md with no H2 headings at all                                    -> ERROR
#   M6 an out-of-order section appended: the fresh index must list it among the places where file
#      order and date order disagree (the detector can fire)
#   M7 a section headed `## 🛑 <ISO date>: ...` appended: the fresh index must read it as `iso`,
#      not `embedded` (the leading-symbol clause of the currency gate's grammar reaches this index)
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "HISTORY_INDEX=ERROR cannot reach the repo root"; exit 2; }

MODE=write HIST=documentation/HISTORY.md IDX=documentation/HISTORY_INDEX.md
CUR=scripts/history_currency_gate.sh
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE=check ;;
    --stdout) MODE=stdout ;;
    --selftest) MODE=selftest ;;
    --history) HIST=${2-}; shift ;;
    --index) IDX=${2-}; shift ;;
    --currency-gate) CUR=${2-}; shift ;;
    *) echo "usage: $0 [--check|--stdout|--selftest] [--history F] [--index F] [--currency-gate F]"
       echo "HISTORY_INDEX=ERROR"; exit 2 ;;
  esac
  shift
done

if [ "$MODE" = selftest ]; then
  T=$(mktemp -d) || { echo "HISTORY_INDEX_SELFTEST=FAIL"; exit 1; }
  trap 'rm -rf "$T"' EXIT
  fails=0
  run() { bash "$0" --check --history "$T/H.md" --index "$T/I.md" --currency-gate "$T/C.sh" 2>&1; }
  reset() { cp "$HIST" "$T/H.md" && cp "$CUR" "$T/C.sh" \
            && bash "$0" --stdout --history "$T/H.md" --currency-gate "$T/C.sh" > "$T/I.md"; }
  expect() {  # expect LABEL VERDICT OUTPUT
    if grep -qx "HISTORY_INDEX=$2" <<<"$3"; then echo "  [ok]   $1 -> $2"
    else echo "  [FAIL] $1: expected HISTORY_INDEX=$2, got: $(grep '^HISTORY_INDEX=' <<<"$3")"; fails=$((fails+1)); fi
  }
  reset || { echo "  [FAIL] could not build the unmodified copies"; echo "HISTORY_INDEX_SELFTEST=FAIL"; exit 1; }
  expect "control: unmodified copies" CURRENT "$(run)"
  printf '\n## 2099-01-01 — a mutant section\n\ntext\n' >> "$T/H.md"
  expect "M1 new section, index not regenerated" STALE "$(run)"
  reset; n=$(grep -n '^| [0-9]' "$T/I.md" | sed -n 5p | cut -d: -f1)
  sed -i "${n}d" "$T/I.md"
  expect "M2 one index row deleted" STALE "$(run)"
  reset; n=$(grep -n '^| [0-9]' "$T/I.md" | sed -n 5p | cut -d: -f1)
  sed -i "${n}{h;d};$((n+1)){G}" "$T/I.md"
  expect "M3 two adjacent index rows swapped" STALE "$(run)"
  reset; grep -v "re.finditer(r'" "$T/C.sh" > "$T/C2.sh" && mv "$T/C2.sh" "$T/C.sh"
  expect "M4 currency-gate pattern removed" ERROR "$(run)"
  reset; grep -v '^## ' "$T/H.md" > "$T/H2.md" && mv "$T/H2.md" "$T/H.md"
  expect "M5 no H2 headings" ERROR "$(run)"
  reset; printf '\n## 2001-02-03 — a mutant out-of-order section\n\ntext\n' >> "$T/H.md"
  out=$(bash "$0" --stdout --history "$T/H.md" --currency-gate "$T/C.sh" 2>&1)
  if grep -q '^- line [0-9]*: 2001-02-03 ' <<<"$out"; then echo "  [ok]   M6 appended out-of-order section is listed as a disagreement"
  else echo "  [FAIL] M6 appended out-of-order section is NOT listed as a disagreement"; fails=$((fails+1)); fi
  reset; printf '\n## \xf0\x9f\x9b\x91 2098-07-06: a mutant symbol-led section\n\ntext\n' >> "$T/H.md"
  out=$(bash "$0" --stdout --history "$T/H.md" --currency-gate "$T/C.sh" 2>&1)
  if grep -q '^| [0-9]* | 2098-07-06 | iso | ' <<<"$out"; then echo "  [ok]   M7 a symbol-led ISO heading is read as iso"
  else echo "  [FAIL] M7 a symbol-led ISO heading is NOT read as iso: $(grep '2098-07-06' <<<"$out" | head -1)"; fails=$((fails+1)); fi
  if [ "$fails" -eq 0 ]; then echo "HISTORY_INDEX_SELFTEST=PASS"; exit 0; fi
  echo "HISTORY_INDEX_SELFTEST=FAIL"; exit 1
fi

python3 - "$MODE" "$HIST" "$IDX" "$CUR" <<'PY'
import collections, datetime, re, sys, unicodedata
mode, hist, idx, cur = sys.argv[1:5]

def err(msg):
    print("  [ERROR] " + msg + " -- nothing was compared" if mode == "check" else "  [ERROR] " + msg,
          file=sys.stderr if mode == "stdout" else sys.stdout)
    print("HISTORY_INDEX=ERROR", file=sys.stderr if mode == "stdout" else sys.stdout)
    sys.exit(2)

try:
    doc = open(hist, encoding="utf-8").read()
    gate = open(cur, encoding="utf-8").read()
except OSError as e:
    err("cannot read an input: %s" % e)

# The ISO grammar is the currency gate's own pattern, not a copy of it.
pm = re.findall(r"re\.finditer\(r'([^']+)', doc, re\.M\)", gate)
if len(pm) != 1:
    err("found %d heading pattern(s) in %s where exactly 1 is expected; the ISO grammar is read "
        "from there so the two cannot disagree" % (len(pm), cur))
ISO = re.compile(pm[0])
MONTHS = ["january", "february", "march", "april", "may", "june", "july", "august",
          "september", "october", "november", "december"]
PROSE = re.compile(r"^[^\w]*?(%s)\s+(\d{1,2})\b.*?\b((?:19|20)\d{2})\b" % "|".join(MONTHS), re.I)
EMB = re.compile(r"\b(\d{4})-(\d{2})-(\d{2})\b")

# GATE 4's heading rule and slug rule (scripts/doc_gates.d/20_retract_links_status.sh, gate_links).
HEAD = re.compile(r'^(#{1,6})\s+(.*?)\s*$', re.M)
def slug(t):
    t = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', t)
    t = re.sub(r'[`*~]', '', t).strip().lower()
    t = ''.join(c for c in t if c in ' -' or unicodedata.category(c)[0] in 'LM'
                or unicodedata.category(c) in ('Nd', 'Nl', 'Pc'))
    return t.replace(' ', '-')

def lineno(pos):
    return doc.count("\n", 0, pos) + 1

seen, anchor_at = collections.Counter(), {}
for m in HEAD.finditer(doc):
    s = slug(m.group(2)); seen[s] += 1
    anchor_at[lineno(m.start())] = s if seen[s] == 1 else "%s-%d" % (s, seen[s] - 1)

rows, undated = [], []
for m in re.finditer(r'^##[ \t].*$', doc, re.M):
    line, raw = lineno(m.start()), m.group(0)
    if line not in anchor_at:
        err("line %d of %s is an H2 heading GATE 4's rule does not see; cannot anchor it" % (line, hist))
    text = re.sub(r'^##\s+', '', raw).strip()
    date = end = None
    try:
        g = ISO.match(raw)
        if g:
            tier = "iso"
            y, mo, d = int(g.group(1)), int(g.group(2)), int(g.group(3))
            date = datetime.date(y, mo, d)
            if g.lastindex and g.lastindex >= 5 and g.group(5):
                emo = int(g.group(4)) if g.group(4) else mo
                end = datetime.date(y + (1 if emo < mo else 0), emo, int(g.group(5)))
        elif PROSE.match(text):
            tier = "prose"; p = PROSE.match(text)
            date = datetime.date(int(p.group(3)), MONTHS.index(p.group(1).lower()) + 1, int(p.group(2)))
        elif EMB.search(text):
            tier = "embedded"; e = EMB.search(text)
            date = datetime.date(int(e.group(1)), int(e.group(2)), int(e.group(3)))
        else:
            tier = None
    except ValueError as exc:
        err("line %d of %s: a date that is not a calendar date (%s)" % (line, hist, exc))
    item = dict(line=line, text=text, tier=tier, date=date, end=end, anchor=anchor_at[line])
    (rows if tier else undated).append(item)

iso_n = sum(1 for r in rows if r["tier"] == "iso")
if iso_n == 0:
    err("0 headings of %s match the currency gate's grammar; the grammar changed under this "
        "index" % hist)

def disagreements(items):
    out, prev = [], None
    for r in items:
        if prev is not None and r["date"] < prev["date"]:
            out.append((r, prev))
        prev = r
    return out
inv_all = disagreements(rows)
inv_iso = disagreements([r for r in rows if r["tier"] == "iso"])

def cell(t):
    return t.replace("\\", "\\\\").replace("|", "\\|")
def when(r):
    s = r["date"].isoformat()
    return s + (" to " + r["end"].isoformat() if r["end"] and r["end"] != r["date"] else "")

src = hist.split("/")[-1]
L = []
L.append("# HISTORY.md: chronological index")
L.append("")
L.append("<!-- GENERATED by scripts/history_index.sh from documentation/HISTORY.md. Do not edit by hand:")
L.append("     run `bash scripts/history_index.sh` after any change to HISTORY.md. `--check` (GATE 91 of")
L.append("     scripts/doc_gates.sh, `history-index`) fails while this file is out of date. -->")
L.append("")
L.append("[HISTORY.md](%s) is append-only: a section stays where it was first written and is never moved"
         " or reworded. Some sections were written after later-dated ones, so the file is not in date"
         " order everywhere. This page lists its dated sections in date order, with the line each starts"
         " on, and names every place where the file's order and the date order disagree."
         " `bash scripts/history_index.sh --check` prints `HISTORY_INDEX=CURRENT` while this page"
         " matches HISTORY.md, `HISTORY_INDEX=STALE` once it does not, and `HISTORY_INDEX=ERROR` when"
         " it could not compare; `--selftest` prints `HISTORY_INDEX_SELFTEST=PASS` when every one of"
         " its mutants is caught." % src)
L.append("")
L.append("**How a date is read.** Only `##` section headings are indexed. The date is taken from the"
         " heading, in this order: an ISO date at its start (after at most one leading emoji or symbol), in the grammar scripts/history_currency_gate.sh"
         " uses (`iso`; a range such as `2026-07-04/05` is shown with its last day); otherwise a month name"
         " and day at its start, with the year that follows (`prose`; for a range, the first day named);"
         " otherwise an ISO date elsewhere in it (`embedded`). Dates are as written: headings mix PDT, PT"
         " and UTC, and none is converted. Sections sort by their first day; ties keep file order."
         " Headings with no date are listed last, in file order.")
L.append("")
L.append("**Where file order and date order disagree.** A section whose first day is earlier than that"
         " of the dated section above it in the file: %d place(s) over all %d dated sections, %d of them"
         " among the %d `iso` sections alone." % (len(inv_all), len(rows), len(inv_iso), iso_n))
L.append("")
for r, p in inv_all:
    L.append("- line %d: %s ([%s](%s#%s)), below line %d: %s" % (
        r["line"], r["date"].isoformat(), "section", src, r["anchor"], p["line"], p["date"].isoformat()))
L.append("")
L.append("## Dated sections, in date order")
L.append("")
L.append("| # | Date | Read as | Line | Section |")
L.append("|---:|---|---|---:|---|")
order = sorted(rows, key=lambda r: (r["date"], r["line"]))
for i, r in enumerate(order, 1):
    L.append("| %d | %s | %s | %d | [open](%s#%s) %s |" % (
        i, when(r), r["tier"], r["line"], src, r["anchor"], cell(r["text"])))
L.append("")
L.append("## Sections with no date in the heading, in file order")
L.append("")
L.append("| Line | Section |")
L.append("|---:|---|")
for r in undated:
    L.append("| %d | [open](%s#%s) %s |" % (r["line"], src, r["anchor"], cell(r["text"])))
L.append("")
fresh = "\n".join(L)

if mode == "stdout":
    sys.stdout.write(fresh); sys.exit(0)
if mode == "write":
    open(idx, "w", encoding="utf-8").write(fresh)
    print("  wrote %s: %d dated section(s) (%d iso), %d undated, %d disagreement(s) of file and date order"
          % (idx, len(rows), iso_n, len(undated), len(inv_all)))
    sys.exit(0)
try:
    have = open(idx, encoding="utf-8").read()
except OSError as e:
    err("cannot read the committed index %s: %s" % (idx, e))
print("  [info] %s: %d dated H2 section(s) (%d iso, the currency gate's grammar), %d undated; %d place(s)"
      " where file order and date order disagree" % (hist, len(rows), iso_n, len(undated), len(inv_all)))
if have == fresh:
    print("  [ok]   %s is byte-identical to a fresh generation" % idx)
    print("HISTORY_INDEX=CURRENT"); sys.exit(0)
a, b = have.split("\n"), fresh.split("\n")
k = next((j for j in range(min(len(a), len(b))) if a[j] != b[j]), min(len(a), len(b)))
print("  [FAIL] %s differs from a fresh generation from line %d" % (idx, k + 1))
print("         committed: %s" % (a[k] if k < len(a) else "<end of file>"))
print("         fresh:     %s" % (b[k] if k < len(b) else "<end of file>"))
print("         Regenerate it: bash scripts/history_index.sh")
print("HISTORY_INDEX=STALE"); sys.exit(1)
PY
