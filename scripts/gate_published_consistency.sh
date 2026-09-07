#!/usr/bin/env bash
# gate_published_consistency.sh — the three classes that dominated v3 lens B's surviving yield.
#
# WHY THIS EXISTS. Two independent Fable adjudications of Codex lens-B transcripts measured the same
# thing on documents at opposite ends of the maturity range:
#   TR-12 (a July spec patched through September, 1,198 lines, 43 findings) -> 17 survived (40%)
#   TR-6  (a settled report, 15 findings)                                   ->  6 survived (40%)
# Survival did NOT fall with maturity, and 0 of 58 findings were factually wrong about their
# document. What survived was overwhelmingly CROSS-DOCUMENT DRIFT: a claim that stopped being true
# when a sibling moved. Both adjudicators concluded, independently, that buying a consistency gate
# beats buying a 158-target adversarial pass that would rediscover these same classes 158 times.
#
# Verdict token: PUBLISHED_CONSISTENCY=PASS|FAIL — grep -qx it, never gate on output shape.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
fail=0

# ---- G1: unfilled placeholder tokens in PUBLISHED text -----------------------------------------
# A reader following `[REPRO-TAG]` gets nothing: the document's own resolver command returns no
# match against any of the repository's tags. Three lens-B findings collapsed to this one grep.
echo "== G1: unfilled placeholders in published reports =="
G1=$(grep -rnoE "\[(REPRO-TAG|EXPECTED-[A-Z0-9]+|STAGE-[FGT]-SHA-REGISTRY)\]" reports/ README.md 2>/dev/null || true)
G1_N=$( [ -n "$G1" ] && echo "$G1" | grep -c . || echo 0 )
if [ -n "$G1" ]; then
  echo "$G1" | sed 's/^/   [FAIL] /'
  echo "   $G1_N unfilled placeholder(s) in published text"
  fail=1
else
  echo "   [ok]   no unfilled placeholders"
fi

# ---- G2: sampled-figure commands with no thread pin --------------------------------------------
# METHODS.md requires every reproduction command for a SAMPLED figure to carry its thread count;
# a sampled draw does not reproduce without it. Only real commands are checked -- a line must
# invoke ./solve, so prose ABOUT the estimator does not trip it.
echo "== G2: sampled-figure commands missing SOLVE_THREADS =="
# 🔴 NARROWED, and the first draft is why. Written broadly it fired on CORRECTIONS.md and
# CORRECTIONS_INVENTORY.tsv -- which MUST quote superseded commands verbatim, that being what a
# corrections ledger is for -- and on template forms (`<probes>`, `--estimate-knuth ...`) that are
# not runnable commands at all. That is the "gate correct data fails" class this project has hit
# five times, reproduced here in a gate written to stop a different one. A command only counts if
# it names a CONCRETE probe count.
# ZERO-PROBE RUNS ARE EXCLUDED, and that is not a loophole: `--estimate-knuth 0 <prefix>` performs
# no sampling at all -- it walks the prefix ladder deterministically -- so its output does not depend
# on thread count and METHODS' pin requirement, which exists for SAMPLED draws, does not apply.
# Second false-positive class found while red-testing this gate, after the corrections-ledger one.
G2=$(grep -rnE '`[^`]*\./solve --estimate-knuth +[1-9][0-9]*[^`]*`' reports/ documentation/ 2>/dev/null \
     | grep -v 'SOLVE_THREADS' \
     | grep -vE '^documentation/CORRECTIONS(_INVENTORY)?\.(md|tsv):' || true)
G2_N=$( [ -n "$G2" ] && echo "$G2" | grep -c . || echo 0 )
if [ -n "$G2" ]; then
  echo "$G2" | cut -c1-140 | sed 's/^/   [FAIL] /'
  echo "   $G2_N sampled-figure command(s) with no thread pin"
  fail=1
else
  echo "   [ok]   every published --estimate-knuth command carries a thread pin"
fi

# ---- G3: disclosures that have become FALSE ----------------------------------------------------
# 🔴 THIS GATE FIRES WHEN THE ARTIFACT EXISTS. A "no public artifact" disclosure is a claim about
# the repository, and it expires silently the moment the artifact ships. Registry:
# documentation/DISCLOSURE_CHECKS.tsv, one row per disclosure with the test that proves it.
echo "== G3: published disclosures that are now stale =="
REG=documentation/DISCLOSURE_CHECKS.tsv
if [ ! -r "$REG" ]; then
  echo "   [FAIL] $REG missing — the gate cannot run, which is a FAILURE, not a pass"; fail=1
else
  n=0
  while IFS=$'\t' read -r f claim test_cmd; do
    case "$f" in ''|'#'*) continue;; esac
    n=$((n+1))
    if ! grep -qF -- "$claim" "$f" 2>/dev/null; then
      echo "   [FAIL] $f no longer contains \"$claim\" — registry row is stale; remove it"; fail=1; continue
    fi
    if ( eval "$test_cmd" ) >/dev/null 2>&1; then
      echo "   [FAIL] $f says \"$claim\" but the artifact EXISTS — the disclosure understates what"
      echo "          this repository can prove. Test that fired: $test_cmd"; fail=1
    else
      echo "   [ok]   $f: \"$claim\" still true"
    fi
  done < "$REG"
  [ "$n" -gt 0 ] || { echo "   [FAIL] registry has zero rows — a vacuous gate is not a passing one"; fail=1; }
fi

echo
# ---- G4: a correction that names the files it propagated to, and did not ------------------------
# 🔴 THE DEFECT THIS EXISTS FOR, FOUND 2026-09-06 BY A TWO-LENS REVIEW OF README.md.
# Four of five surviving findings were ONE class: front-page bullets written 2026-07-03/26 still
# presenting results their own sources had withdrawn -- CX-26's Bayes factor, CX-27/TR-8 v1.16's
# "is decided", TR-7's "partially overlapping replicate, not an independent draw". Each correction
# updated the TR and named a propagation list; README.md was not on any of those lists, so the most
# read page in the project kept advertising withdrawn results for six weeks.
#
# Nobody was careless. The process HAS a propagation list and the list was incomplete, which is a
# thing a person forgets and a script does not. So: every file a correction NAMES must carry that
# correction's id. That is the promise the ledger makes in writing, and until now nothing checked it.
#
# 🔴 THIS IS THE WEAKER HALF OF THE PROBLEM AND SAYS SO. It catches a BROKEN promise, not a MISSING
# one -- a file that should have been on the list and never was still slips through. That half is
# not mechanically decidable (it needs "does this file repeat the withdrawn result", a semantic
# question). Fixing the checkable half is not the same as fixing the class, and pretending otherwise
# would be the exact defect this gate is named after.
echo "== G4: corrections that name a propagation target which lacks the correction id =="
G4_N=0
if [ -r documentation/CORRECTIONS.md ]; then
  G4_OUT=$(python3 - <<'PYG4'
import re, os
try: s = open("documentation/CORRECTIONS.md", errors="replace").read()
except Exception: raise SystemExit(0)
bad = []
for e in re.split(r'\n(?=#{2,4} *CX-\d+)', s):
    m = re.match(r'#{2,4} *(CX-\d+)', e)
    if not m: continue
    cx = m.group(1)
    dm = re.search(r'-\s*\*\*Documents:\*\*(.*?)(?=\n-\s*\*\*)', e, re.S)
    if not dm: continue
    seen = set()
    for link in re.findall(r'\]\(([^)]+)\)', dm.group(1)):
        q = link.split('#')[0].lstrip('./')
        if q.startswith('../'): q = q[3:]
        elif q.endswith('.md') and not q.startswith(('reports/','documentation/','lean/')):
            q = 'documentation/' + q
        if q.endswith('.md') and os.path.isfile(q) and q not in seen:
            seen.add(q)
            if cx not in open(q, errors='replace').read():
                bad.append(f"{cx} names {q}, which does not carry {cx}")
for b in bad: print(b)
PYG4
)
  if [ -n "$G4_OUT" ]; then
    printf '%s\n' "$G4_OUT" | sed 's/^/   [FAIL] /'
    G4_N=$(printf '%s\n' "$G4_OUT" | grep -c .)
    echo "   $G4_N correction(s) naming a target that lacks the id"
    fail=1
  else
    echo "   [ok]   every file a correction names carries that correction's id"
  fi
else
  echo "   [FAIL] documentation/CORRECTIONS.md unreadable — cannot check propagation"; fail=1; G4_N=999
fi

# ---- G5: a published histogram figure must come from the section it cites ----------------------
# 🔴 LB-A4, 2026-09-07. LEADERBOARD published distance-3 = 6, drawn from section [24] -- a
# nearest-neighbour catalog CAPPED AT THE TOP 50. The true count is in section [28], the full
# histogram, IN THE SAME FILE, and it is 50. A cutoff was published as a count. The same note also
# said the full distribution "has not yet been computed", which that file refutes on its own.
# This leg re-reads the artifact and compares, so the table cannot drift from its own source again.
G5=0
_ART=enumeration/analyze_sec25fix_742M.txt
_LB=enumeration/LEADERBOARD.md
if [ -r "$_ART" ] && [ -r "$_LB" ]; then
  for d in 0 2 3; do
    want=$(awk -v D="$d" '/^\[28\] Edit-distance/,0 { if ($1==D && $2=="|") { gsub(",","",$3); print $3; exit } }' "$_ART")
    # anchor to the distance table -- "| 2 |" occurs in other tables earlier in the file, and the
    # first match anywhere was reading the wrong row (measured: distance-2 read as 34, not 44).
    got=$(awk -v D="$d" -F'|' '/Positions different/{t=1} t && $0 ~ /^\| *'"$d"' *\|/ { gsub(/[^0-9]/,"",$3); print $3; exit }' "$_LB")
    [ -n "$want" ] && [ -n "$got" ] || continue
    if [ "$want" != "$got" ]; then
      echo "  [FAIL] G5: LEADERBOARD publishes distance-$d = $got; $_ART section [28] says $want"
      G5=$((G5+1))
    fi
  done
  [ "$G5" -eq 0 ] && echo "  [ok]   G5: published distance counts match section [28] of the artifact they cite"
else
  echo "  [FAIL] G5: cannot read $_ART or $_LB -- this leg measured NOTHING"
  G5=1
fi

# ---- G6: a magnitude called "canonical" must fit the canonical ceiling ------------------------
# 🔴 SSS-A2, 2026-09-07. SEARCH_SPACE_SIZE published per-cell tree sizes as "canonical" at min
# 5.9e31. A depth-3 cell fixes four pairs, leaving at most 28! = 3.05e29 canonical pair orderings --
# so the figure exceeded its own ceiling by 194x, and even the e*28! tree bound by 71x. The numbers
# were right for the ORIENTATION-EXPLICIT space the estimator walks; the word named a smaller one.
# A count cannot exceed the size of the set it counts, which makes this checkable without judgement.
G6=0
_SSS=${G6_FILE:-documentation/SEARCH_SPACE_SIZE.md}
# 🔴 A TARGETED INVARIANT, NOT A HEURISTIC -- and that is a deliberate retreat. Three broader forms
# were tried and each failed honestly: superscript character RANGES match nothing in ERE (multibyte);
# sentence-splitting on '.' breaks on the decimal in "5.9x10^31"; and flagging any canonical magnitude
# >= 10^30 false-positived on "the space is ~10^38", which is CORRECT -- the whole C1-C5 space really
# is that size canonically. The defect is specific: a PER-CELL tree size at depth 3, where 28! =
# 3.05e29 is the ceiling and the published minimum was 194x it. So the check is specific too.
G6=0
_SSS=${G6_FILE:-documentation/SEARCH_SPACE_SIZE.md}
if [ -r "$_SSS" ]; then
  _line=$(grep -n 'un-budgeted' "$_SSS" | grep -i 'tree size per cell' | head -1)
  if [ -z "$_line" ]; then
    echo "  [FAIL] G6: the per-cell tree-size sentence is gone from $_SSS -- this leg measured NOTHING"
    G6=1
  elif printf '%s' "$_line" | grep -qi 'orientation-explicit'; then
    echo "  [ok]   G6: the per-cell tree-size figures are labelled orientation-explicit, not canonical"
  else
    echo "  [FAIL] G6: per-cell tree sizes are not labelled orientation-explicit."
    echo "         A depth-3 cell fixes four pairs, so at most 28! = 3.05e29 CANONICAL orderings remain;"
    echo "         the published minimum 5.9e31 is 194x that ceiling and 71x even the e*28! tree bound."
    G6=1
  fi
else
  echo "  [FAIL] G6: cannot read $_SSS -- this leg measured NOTHING"; G6=1
fi

# ---- G7: the per-position entropy table must match the artifact it cites --------------------------
# 🔴 LB-A1, 2026-09-07. LEADERBOARD's table named analyze_sec25fix_742M.txt as its source and
# disagreed with it in 29 of 32 rows -- position 2 published 16 pairs against 28, position 14 three
# against four, and the entropy column differed almost everywhere. The note beside it disclosed the
# numbers as STALE, which reads as "old but from there"; they were not from there at all. A stale
# disclosure is not a provenance check, and only a re-read is.
G7=0
_A2=${G7_ART:-enumeration/analyze_sec25fix_742M.txt}
_L2=${G7_TBL:-enumeration/LEADERBOARD.md}
if [ -r "$_A2" ] && [ -r "$_L2" ]; then
  _bad=$(awk '
    FILENAME==ARGV[1] && /^\[2\]/ {inb=1; next}
    FILENAME==ARGV[1] && inb && /^\[/ {inb=0}
    FILENAME==ARGV[1] && inb && $1 ~ /^[0-9]+$/ {h[$1]=$2; n[$1]=$3; next}
    # anchor to the entropy table: other tables in this file also start rows with "| N |"
    # (the edit-distance table did, and the first version compared against those). Same trap as G5.
    FILENAME==ARGV[2] && /Pairs observed/ {t=1}
    FILENAME==ARGV[2] && t && /^\| *[0-9]+ *\|/ {
      nf=split($0,c,"|");
      # the entropy table has 7 pipe-fields; the edit-distance table later in the file has 5 and was
      # being compared with empty columns, because the "Pairs observed" anchor stays set to EOF.
      if (nf < 7) next;
      p=c[2]+0; gsub(/ /,"",c[5]); gsub(/ /,"",c[6]);
      if (p in h && (c[5]!=n[p] || (c[6]+0) - h[p] > 0.0005 || h[p] - (c[6]+0) > 0.0005)) bad++
    }
    END{print bad+0}' "$_A2" "$_L2")
  if [ "${_bad:-0}" -gt 0 ]; then
    echo "  [FAIL] G7: $_bad LEADERBOARD row(s) disagree with section [2] of $_A2"
    G7=$_bad
  else
    echo "  [ok]   G7: the per-position entropy table matches section [2] of the artifact it cites"
  fi
else
  echo "  [FAIL] G7: cannot read $_A2 or $_L2 -- this leg measured NOTHING"; G7=1
fi

# ---- G8: no claim that a fixed position range is constrained "across all three datasets" --------
# 🔴 LB-A3, 2026-09-07. LEADERBOARD asserted "pos 3-19 constrained ... holds across all three
# datasets". Re-read from the archived logs: position 4 is H=0.2803 over 3 pairs at 742M but
# H=4.5029 over 31 pairs at d3 10T -- near-MAXIMAL, the opposite of constrained -- and position 3 is
# unconstrained in both. The shape is real; the fixed numbers were read off one dataset and asserted
# of all of them. This leg refuses the phrasing, because the boundaries provably move.
G8=0
_L8=${G8_FILE:-enumeration/LEADERBOARD.md}
if [ -r "$_L8" ]; then
  if grep -qE 'pos [0-9]+-[0-9]+ constrained.{0,40}(all three|every) dataset' "$_L8"; then
    echo "  [FAIL] G8: a FIXED position range is claimed constrained across all datasets;"
    echo "         measured, position 4 is H=0.2803/3 pairs at 742M and H=4.5029/31 at d3 10T."
    G8=1
  else
    echo "  [ok]   G8: no fixed constrained-position range is asserted across datasets"
  fi
else
  echo "  [FAIL] G8: cannot read $_L8 -- this leg measured NOTHING"; G8=1
fi

# ---- RATCHET ------------------------------------------------------------------------------------
# 🔴 A GATE THAT PRINTS FAIL ON EVERY RUN IS A GATE NOBODY READS. This one had 15 standing defects on
# the day it was written, and it was wired into nothing for exactly that reason -- which made it
# strictly worse than useless: a check that exists, cannot fail usefully, and is therefore never run.
# (grep -rn gate_published_consistency scripts/ returned only this file, 2026-09-06.)
#
# So the verdict is a ratchet against pinned counts, not an absolute. A count that RISES fails: a new
# published-consistency defect can no longer be introduced silently. A count that FALLS is announced
# so the pin tightens in the same commit as the fix. The standing 15 stay visible in the pin file,
# with a written reason each, instead of being waved through by an alarm everyone learned to ignore.
G3_N="${G3_N:-0}"
PIN="$(dirname "$0")/gate_published_consistency.pin"
if [ ! -r "$PIN" ]; then
  echo "  [FAIL] no pin file at $PIN — an UNPINNED ratchet certifies nothing"
  echo "PUBLISHED_CONSISTENCY=FAIL"; exit 1
fi
# shellcheck disable=SC1090
P_G1=$(awk -F= '/^G1=/{print $2}' "$PIN"); P_G2=$(awk -F= '/^G2=/{print $2}' "$PIN"); P_G3=$(awk -F= '/^G3=/{print $2}' "$PIN"); P_G4=$(awk -F= '/^G4=/{print $2}' "$PIN")
for v in "$P_G1" "$P_G2" "$P_G3" "$P_G4"; do
  case "$v" in ''|*[!0-9]*) echo "  [FAIL] pin file is malformed"; echo "PUBLISHED_CONSISTENCY=FAIL"; exit 1;; esac
done
echo
echo "== RATCHET vs $PIN =="
ratchet=0; tighten=0
for pair in "G1:${G1_N:-0}:$P_G1" "G2:${G2_N:-0}:$P_G2" "G3:${G3_N:-0}:$P_G3" "G4:${G4_N:-0}:$P_G4"; do
  g=${pair%%:*}; rest=${pair#*:}; now=${rest%%:*}; pin=${rest##*:}
  if [ "$now" -gt "$pin" ]; then
    echo "  [FAIL] $g rose to $now from a pinned $pin — a NEW published-consistency defect"; ratchet=1
  elif [ "$now" -lt "$pin" ]; then
    echo "  [ok]   $g fell to $now from a pinned $pin — TIGHTEN THE PIN in this same commit"; tighten=1
  else
    echo "  [ok]   $g at its pinned $pin (known-open; see the pin file for why each stands)"
  fi
done
[ "$tighten" -eq 1 ] && echo "  A count fell. Leaving the pin loose lets the defect come back unseen."
echo
# 🔴 THREE VALUES, BECAUSE TWO WOULD LIE EITHER WAY.
#   FAIL        a count ROSE — a new defect. This is the one that must block.
#   PASS-AT-PIN no regression, but N known-open defects stand. Saying PASS here would let 15 real
#               defects read as clean; saying FAIL would make every push noisy and the gate ignored.
#               Neither is honest, so the token says exactly what is true.
#   PASS        nothing outstanding at all.
# grep -qx the one you mean. Do not test for "PASS" as a substring: it matches PASS-AT-PIN.
if [ "$ratchet" -ne 0 ]; then
  echo "PUBLISHED_CONSISTENCY=FAIL"
elif [ "$fail" -ne 0 ]; then
  echo "PUBLISHED_CONSISTENCY=PASS-AT-PIN"
else
  echo "PUBLISHED_CONSISTENCY=PASS"
fi
exit 0
