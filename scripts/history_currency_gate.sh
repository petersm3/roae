#!/usr/bin/env bash
# HISTORY_CURRENCY=PASS|FAIL|ERROR
#
# documentation/HISTORY.md is the outward-facing narrative log, and NOTHING checked that it keeps
# up. MEASURED 2026-09-07: 2026-09-03 is a whole uncovered day — 29 commits, no heading, and the
# only "2026-09-03" string in the published file is a FILENAME citation inside another day's entry.
# No private draft covers it either. Separately, 42 of 48 commits on 2026-09-07 are unnarrated,
# because that day's entry was written at commit #43 of 48 — the file is written in same-day
# batches, so its failure mode is a day skipped entirely, or a day still in progress when its own
# entry is written.
#
# 🔴 THE RANGE-HEADING TRAP, which is why this is not a five-line script. The file uses THREE
# heading grammars, and a parser taking only the leading ISO date would read `## 2026-08-08/08-30`
# as covering 08-08 alone and MANUFACTURE 21 phantom gaps across August. A gate that cries about
# 21 days that are in fact covered gets switched off in a week, and then the one real gap goes
# unnoticed too. All three grammars are parsed here:
#     ## 2026-09-07              a single day
#     ## 2026-07-04/05           bare DD after the slash, same month
#     ## 2026-08-08/08-30        full MM-DD after the slash
# Any of the three may carry ONE leading emoji/symbol token before the date (2026-09-26):
#     ## 🛑 2026-08-16: ...       a symbol run, then whitespace, then the ISO date
# MEASURED 2026-09-26: `## 🛑 2026-08-16: a PUBLICATION FREEZE, ...` (HISTORY.md:6621) was the one
# ISO-dated H2 this grammar missed. 2026-08-16 still read as covered, but only because two range headings
# (the `2026-08-08/08-30` and `2026-08-15/16` sections) span it, and scripts/history_index.sh, which reads this pattern, filed it as `embedded`. The
# token must be symbols only (no letter, digit or `_`) and be followed by whitespace, so a WORD
# before the date (`## Infrastructure (2026-04-22)`) is still not parsed: that is prose.
# Non-ISO headings (e.g. "## Phase B cascade ... (2026-05-13/14 PT)") are deliberately NOT parsed:
# guessing at prose is how a gate starts inventing coverage.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "HISTORY_CURRENCY=ERROR cannot reach repo root"; exit 2; }
DAYS=${HISTORY_WINDOW_DAYS:-14}
REF=${HISTORY_REF:-origin/main}
# Days known-open and deliberately not yet written. A gap listed here is DEBT, not absence of a
# defect — the count is printed so it cannot quietly grow.
# 🔴 `${VAR-default}`, NOT `${VAR:-default}`. With the colon, an EMPTY value falls back to the
# default, so `HISTORY_KNOWN_GAPS= ` cannot express "no recorded debt" — and the red test that
# clears the list silently keeps it, reporting PASS. Measured here on the first attempt; the same
# trap was found in citation_line_gate.sh's allow-list the same day. A gate whose red test cannot
# be armed has not been red-tested.
# 🔴 2026-09-08: THE DEFAULT IS NOW EMPTY, and it must stay empty until a day is genuinely left
# open on purpose. It carried `2026-09-03` from the day this gate was written; that day was
# narrated on 2026-09-08 (`## 2026-09-03 — a sweep through the checks themselves…`), so the entry
# had become an allowance for something already fixed — a clause that can never fail, which is the
# verifier-closure class this repo refuses elsewhere. MEASURED before removing it: against the
# narrated file the gate reaches PASS on COVERAGE ALONE (0 gaps, so no other day was leaning on
# this list), and against a copy with the 2026-09-03 section deleted it read PASS with the old
# default and FAIL with the empty one. Do not re-add a date here to quiet a failure; write the day.
KNOWN=${HISTORY_KNOWN_GAPS-}

# --selftest (2026-09-26): the heading grammar, judged on throwaway git repos, never this one.
# Each case is a one-heading HISTORY.md committed today; the verdict it must give is fixed below.
# Then each MUTANT of this script's own pattern is run over the same cases and must disagree with
# at least one expectation, or the case table could not tell it from the real grammar:
#   MU1 the leading-symbol clause removed (the pre-2026-09-26 grammar)   caught by S1/S2
#   MU2 the clause widened to any prefix `.*?`                           caught by W1/W2
#   MU3 the clause widened to any non-space token `\S+\s+`               caught by W2
# Verdict: HISTORY_CURRENCY_SELFTEST=PASS|FAIL, rc 0/1.
if [ "${1-}" = --selftest ]; then
  T=$(mktemp -d) || { echo "HISTORY_CURRENCY_SELFTEST=FAIL"; exit 1; }
  trap 'rm -rf "$T"' EXIT
  today=$(date +%F) fails=0
  CASES=( "P1|PASS|## $today — a plain ISO heading"
          "S1|PASS|## 🛑 $today: a symbol-led heading"
          "S2|PASS|## ⚠️ $today — a symbol with a variation selector"
          "W1|FAIL|## Infrastructure ($today)"
          "W2|FAIL|## Recovered $today — a word-led heading"
          "O1|FAIL|## 🛑 2001-01-01: a symbol-led heading for another day" )
  verdict() {  # verdict GATE_SCRIPT HEADING -> prints the HISTORY_CURRENCY value
    local r; r=$(mktemp -d "$T/r.XXXXXX") || return 1
    mkdir -p "$r/scripts" "$r/documentation" && cp "$1" "$r/scripts/history_currency_gate.sh"
    # A second, plain heading for a day with no commits, so every case parses >= 1 heading and a
    # case the grammar rejects reads FAIL (a gap), not ERROR (no headings at all).
    printf '# History\n\n## 2001-01-02 — an anchor heading\n\n%s\n\ntext\n' "$2" > "$r/documentation/HISTORY.md"
    git -C "$r" init -q && git -C "$r" add -A \
      && git -C "$r" -c user.email=selftest@local -c user.name=selftest commit -q -m selftest || return 1
    HISTORY_REF=HEAD HISTORY_KNOWN_GAPS= bash "$r/scripts/history_currency_gate.sh" 2>&1 \
      | sed -n 's/^HISTORY_CURRENCY=//p'
  }
  table() {  # table GATE_SCRIPT QUIET -> number of cases that disagree with their expectation
    local c id want head got bad=0
    for c in "${CASES[@]}"; do
      id=${c%%|*}; want=${c#*|}; want=${want%%|*}; head=${c#*|*|}
      got=$(verdict "$1" "$head")
      if [ "$got" = "$want" ]; then [ "$2" = quiet ] || echo "  [ok]   $id -> $want: $head"
      else bad=$((bad+1)); [ "$2" = quiet ] || echo "  [FAIL] $id: expected $want, got '${got:-no verdict}': $head"; fi
    done
    return $bad
  }
  SELF="$(pwd)/scripts/history_currency_gate.sh"
  table "$SELF" loud || fails=$((fails+1))
  CLAUSE='(?:[^\w\s]+\s+)?'
  for mu in "MU1|" 'MU2|.*?' 'MU3|(?:\S+\s+)?'; do
    id=${mu%%|*}; rep=${mu#*|}
    python3 - "$SELF" "$T/$id.sh" "$CLAUSE" "$rep" <<'MUT' || { echo "  [FAIL] $id: could not build the mutant"; fails=$((fails+1)); continue; }
import sys
s = open(sys.argv[1], encoding="utf-8").read()
pat = "re.finditer(r'^##\\s+" + sys.argv[3]
if s.count(pat) != 1:
    sys.exit(1)
open(sys.argv[2], "w", encoding="utf-8").write(s.replace(pat, "re.finditer(r'^##\\s+" + sys.argv[4]))
MUT
    if table "$T/$id.sh" quiet; then echo "  [FAIL] $id: the mutant grammar agrees with every case -- the table cannot see it"; fails=$((fails+1))
    else echo "  [ok]   $id: the mutant grammar is caught"; fi
  done
  if [ "$fails" -eq 0 ]; then echo "HISTORY_CURRENCY_SELFTEST=PASS"; exit 0; fi
  echo "HISTORY_CURRENCY_SELFTEST=FAIL"; exit 1
fi

python3 - "$DAYS" "$REF" "$KNOWN" <<'PY'
import re, subprocess, sys, datetime
days, ref, known = int(sys.argv[1]), sys.argv[2], set(x for x in sys.argv[3].split(',') if x)

def sh(*a):
    r = subprocess.run(a, capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None

doc = sh('git', 'show', '%s:documentation/HISTORY.md' % ref)
if doc is None:
    print("  [ERROR] cannot read %s:documentation/HISTORY.md — nothing was checked" % ref)
    print("HISTORY_CURRENCY=ERROR"); sys.exit(2)

covered, headings = set(), 0
for m in re.finditer(r'^##\s+(?:[^\w\s]+\s+)?(\d{4})-(\d{2})-(\d{2})(?:/(?:(\d{2})-)?(\d{2}))?\b', doc, re.M):
    headings += 1
    y, mo, d = int(m.group(1)), int(m.group(2)), int(m.group(3))
    start = datetime.date(y, mo, d)
    if m.group(5) is None:
        covered.add(start); continue
    end_mo = int(m.group(4)) if m.group(4) else mo          # bare DD means "same month"
    end_y = y + (1 if end_mo < mo else 0)                   # a range may cross a year boundary
    end = datetime.date(end_y, end_mo, int(m.group(5)))
    cur = start
    while cur <= end:
        covered.add(cur); cur += datetime.timedelta(days=1)

log = sh('git', 'log', '--since=%d days ago' % days, '--date=short', '--format=%ad', ref)
if log is None:
    print("  [ERROR] cannot read the commit log for %s — nothing was checked" % ref)
    print("HISTORY_CURRENCY=ERROR"); sys.exit(2)
commit_days = {}
for line in log.split('\n'):
    line = line.strip()
    if line:
        commit_days[line] = commit_days.get(line, 0) + 1

# 🔴 CLOSURE, both directions. Zero headings means the grammar changed under this gate; zero
# commit days means the ref or window is wrong. Either way it measured nothing, and nothing must
# never read as "the history is current".
if headings == 0:
    print("  [ERROR] parsed 0 dated headings from HISTORY.md — the heading grammar changed under "
          "this gate, so no day could be marked covered. Nothing was checked.")
    print("HISTORY_CURRENCY=ERROR"); sys.exit(2)
if not commit_days:
    print("  [ERROR] %s has no commits in the last %d days — wrong ref or window; nothing checked"
          % (ref, days))
    print("HISTORY_CURRENCY=ERROR"); sys.exit(2)

gaps = []
for d, n in sorted(commit_days.items()):
    if datetime.date(*map(int, d.split('-'))) not in covered:
        gaps.append((d, n))
new = [g for g in gaps if g[0] not in known]
still = [g for g in gaps if g[0] in known]

print("  [info] %d dated heading(s), %d day(s) covered, %d commit-day(s) in the last %d"
      % (headings, len(covered), len(commit_days), days))
for d, n in still:
    print("  [known-open] %s has %d commit(s) and no entry — recorded debt, not a new gap" % (d, n))
if new:
    for d, n in new:
        print("  [FAIL] %s has %d commit(s) on %s and NO HISTORY.md entry" % (d, n, ref))
    print("  %d unnarrated day(s) beyond the recorded debt" % len(new))
    print("HISTORY_CURRENCY=FAIL"); sys.exit(1)
print("  [ok] every commit-day in the window is narrated, or recorded as known-open debt")
print("HISTORY_CURRENCY=PASS")
PY
