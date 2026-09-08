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
# 🔴 G3_N WAS READ AND NEVER ASSIGNED (found 2026-09-08). This leg printed [FAIL] lines while
# its ratchet compared a default 0 against a pinned 0 and could not fail, and `G3_N=7 bash …` from
# the environment reached the ratchet unchallenged. That is the exact mirror of the "G5–G16 assigned
# and never read" defect fixed the day before, whose comment sits at the ratchet below. Like G1/G2/G4,
# this leg now COUNTS ITS OWN FINDINGS: one per stale row, one per fired artifact, and one for each
# structural failure (registry unreadable, registry empty) so a leg that measured nothing is never
# indistinguishable from a leg that measured clean.
G3_N=0
REG=documentation/DISCLOSURE_CHECKS.tsv
if [ ! -r "$REG" ]; then
  echo "   [FAIL] $REG missing — the gate cannot run, which is a FAILURE, not a pass"; fail=1; G3_N=$((G3_N+1))
else
  n=0
  while IFS=$'\t' read -r f claim test_cmd; do
    case "$f" in ''|'#'*) continue;; esac
    n=$((n+1))
    if ! grep -qF -- "$claim" "$f" 2>/dev/null; then
      echo "   [FAIL] $f no longer contains \"$claim\" — registry row is stale; remove it"; fail=1; G3_N=$((G3_N+1)); continue
    fi
    if ( eval "$test_cmd" ) >/dev/null 2>&1; then
      echo "   [FAIL] $f says \"$claim\" but the artifact EXISTS — the disclosure understates what"
      echo "          this repository can prove. Test that fired: $test_cmd"; fail=1; G3_N=$((G3_N+1))
    else
      echo "   [ok]   $f: \"$claim\" still true"
    fi
  done < "$REG"
  [ "$n" -gt 0 ] || { echo "   [FAIL] registry has zero rows — a vacuous gate is not a passing one"; fail=1; G3_N=$((G3_N+1)); }
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

# ---- G9: a published --branch recipe must carry a budget, and --validate a real path ----------
# 🔴 LB-A6/LB-A7, 2026-09-07. LEADERBOARD published `./solve --branch 24 0 0` with no budget: run as
# printed it prints "No time limit - running to completion" and does not return (measured -- killed
# at 20 s). And `--validate solutions_merged.bin` named a file --merge has NEVER written; the merge
# output is <layer_root>/_merged_/solutions.bin (solve.c:33837, :36922). A reader who pastes the
# block gets a hang and then a missing file. exec_lane runs commands but checks neither, so this is
# a static leg over the published text.
G9=0
_G9F=${G9_FILE:-enumeration/LEADERBOARD.md}
if [ -r "$_G9F" ]; then
  _nb=$(grep -nE '^\s*(SOLVE_[A-Z_]+=[^ ]+ +)*\./solve --(sub-)?branch ' "$_G9F" 2>/dev/null \
          | grep -v 'SOLVE_NODE_LIMIT\|SOLVE_PER_SUB_BRANCH_LIMIT\|REQUIRED' || true)
  if [ -n "$_nb" ]; then
    echo "  [FAIL] G9: a published --branch recipe carries no budget; it will not return:"
    printf '%s\n' "$_nb" | head -3 | sed 's/^/         /'
    G9=$((G9+1))
  fi
  if grep -qE '\-\-validate +solutions_merged\.bin' "$_G9F" 2>/dev/null \
       && ! grep -qE 'never written' "$_G9F"; then
    echo "  [FAIL] G9: --validate names solutions_merged.bin, which --merge does not write"
    G9=$((G9+1))
  fi
  [ "$G9" -eq 0 ] && echo "  [ok]   G9: published --branch recipes carry a budget and --validate names a real path"
else
  echo "  [FAIL] G9: cannot read $_G9F -- this leg measured NOTHING"; G9=1
fi

# ---- G10: a TR revision row that RE-SCOPES must reach the corrections ledger --------------------
# 🔴 CD-A1, 2026-09-07. G4 walks the 35 "## CX-" entries, so a correction recorded ONLY in a TR's
# revision table is outside its universe and G4 reports PASS by construction. Measured: TR-8 v1.16
# (2026-08-30) re-scoped its Gray-code theorem -- "It does not refute their construction, and
# versions v1.0-v1.15 of this report said that it did" -- and CLAIMS_DECIDED still graded the claim
# REFUTED (proven) seven days later, with CITATIONS carrying the same wording in two places.
# A revision row is where a correction is EASIEST to record and HARDEST to propagate.
G10=0
_ledger=documentation/CORRECTIONS.md
if [ -r "$_ledger" ]; then
  for _tr in reports/TR*.md; do
    [ -r "$_tr" ] || continue
    _id=$(basename "$_tr" | grep -oE '^TR[0-9]+')
    _n=$(printf '%s' "$_id" | grep -oE '[0-9]+')
    while IFS= read -r _row; do
      _d=$(printf '%s' "$_row" | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' | head -1)
      [ -n "$_d" ] || continue
      # the ledger must mention that date AND that TR somewhere
      # 🔴 BOTH IN THE SAME ENTRY. The first version asked whether the date and the TR id each
      # appeared ANYWHERE in the ledger; both did, in unrelated entries, so it passed on the very
      # case it was written for -- a check that could not fail. Require one "## " block to carry both.
      if ! awk -v d="$_d" -v n="$_n" '
             /^## /{blk=""}
             {blk=blk"\n"$0}
             {if (blk ~ d && blk ~ ("TR-?" n "[^0-9]")) found=1}
             END{exit found?0:1}' "$_ledger" 2>/dev/null; then
        echo "  [FAIL] G10: $_id revision row dated $_d re-scopes/withdraws, with no ledger entry naming both"
        G10=$((G10+1))
      fi
    done < <(grep -E '^\|.*20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$_tr" 2>/dev/null \
               | grep -iE 're-scoped|rescoped|withdrawn|retracted' || true)
  done
  [ "$G10" -eq 0 ] && echo "  [ok]   G10: every re-scoping TR revision row is named in the corrections ledger"
else
  echo "  [FAIL] G10: cannot read $_ledger -- this leg measured NOTHING"; G10=1
fi

# ---- G11: a published gain series must name the chain the archived run actually picked -----------
# 🔴 SSS-A3, 2026-09-07. SEARCH_SPACE_SIZE published a five-step gain series ending 10.13 bits and
# attributed it to a chain ending in boundary 1. The archived run says "round 5 PICK=2" and pins
# ...,20,21,1,2 -- boundary 2. Recomputed from that file's own candidates, boundary 2 gives 10.11
# bits and boundary 1 gives 5.64. The figure was right and the chain was not, which no numeric check
# would have caught: both numbers are real, they just belong to different steps.
G11=0
_SK=${G11_RUN:-reports/evidence/sk/sk5_7_rounds.out}
_SS=${G11_DOC:-documentation/SEARCH_SPACE_SIZE.md}
if [ -r "$_SK" ] && [ -r "$_SS" ]; then
  _pick=$(grep -oE 'round 5 PICK=[0-9]+' "$_SK" 2>/dev/null | grep -oE '[0-9]+$' | head -1)
  if [ -z "$_pick" ]; then
    echo "  [FAIL] G11: no 'round 5 PICK=' in $_SK -- this leg measured NOTHING"; G11=1
  elif grep -q "round 5 \`PICK=$_pick\`\|PICK=$_pick" "$_SS" 2>/dev/null; then
    echo "  [ok]   G11: the published gain series names the boundary the archived run picked (PICK=$_pick)"
  else
    echo "  [FAIL] G11: the archived run picked boundary $_pick at round 5; the document does not say so"
    G11=1
  fi
else
  echo "  [FAIL] G11: cannot read $_SK or $_SS -- this leg measured NOTHING"; G11=1
fi

# ---- G12: a pre-registered gate must be quoted with ITS OWN threshold ---------------------------
# 🔴 RF-A1, 2026-09-07. TR-2 described a result as "inside its pre-committed 2σ gate" and listed all
# three convergence gates together as though they shared that threshold. As pre-registered
# (reports/evidence/r11/PHASE2_README.md:67-71) gate 1 is a chi-square p-test, gate 2 is 2σ and gate
# 3 is 2.5σ. The 1.9σ figure belongs to gate 3. Every gate still passes on its own criterion, so no
# verdict moved -- what was wrong is the threshold each number was measured against, which is exactly
# the kind of error a numeric check cannot see because every number involved is real.
G12=0
_PH=${G12_PRE:-reports/evidence/r11/PHASE2_README.md}
_T2=${G12_DOC:-reports/TR2_THE_RULES_CONFLICT.md}
if [ -r "$_PH" ] && [ -r "$_T2" ]; then
  # the pre-registration names 2.5σ for gate 3; if TR-2 quotes 1.9σ it must not call it a 2σ gate
  if grep -qE 'within 2\.5σ' "$_PH" 2>/dev/null; then
    if grep -q '1.9σ' "$_T2" 2>/dev/null && ! grep -q 'do NOT share one threshold' "$_T2" 2>/dev/null; then
      echo "  [FAIL] G12: TR-2 quotes 1.9σ without recording that its pre-registered gate is 2.5σ"
      G12=1
    else
      echo "  [ok]   G12: the pre-registered gate thresholds are quoted with the figures they bound"
    fi
  else
    echo "  [FAIL] G12: $_PH no longer states a 2.5σ criterion -- this leg measured NOTHING"; G12=1
  fi
else
  echo "  [FAIL] G12: cannot read $_PH or $_T2 -- this leg measured NOTHING"; G12=1
fi

# ---- G13: "his exception is forced" must not outrun the fiber measurement ----------------------
# 🔴 CD-A2, 2026-09-07. CITATIONS said Van den Berghe's DECLARED exception (pair 3/4) is forced. What
# the fiber sweep shows is weaker and more interesting: reports/evidence/f5/f5_modec_fiber.out
# records "X >= 30: 0" against 12 vectors at X = 29, so AN exception is forced -- no vector orients
# all 30 pairs -- but across those 12 the single miss falls at six different pairs, and only 2 miss
# at #3/4. A general result was being read as a vindication of one author's particular choice.
G13=0
_FB=${G13_FIBER:-reports/evidence/f5/f5_modec_fiber.out}
_CT=${G13_DOC:-documentation/CITATIONS.md}
if [ -r "$_FB" ] && [ -r "$_CT" ]; then
  if ! grep -qE 'X >= 30: 0' "$_FB" 2>/dev/null; then
    echo "  [FAIL] G13: $_FB no longer records X >= 30: 0 -- this leg measured NOTHING"; G13=1
  elif grep -q 'his declared exception is forced' "$_CT" 2>/dev/null; then
    echo "  [FAIL] G13: the declared (pair 3/4) exception is published as forced; the fiber sweep"
    echo "         forces only THAT an exception exists -- the miss falls at six different pairs."
    G13=1
  else
    echo "  [ok]   G13: the forced-exception claim is stated at the scope the fiber sweep supports"
  fi
else
  echo "  [FAIL] G13: cannot read $_FB or $_CT -- this leg measured NOTHING"; G13=1
fi

# ---- G14: a boundary-count projection must not imply ORIENTED uniqueness ------------------------
# 🔴 SSS-A1, 2026-09-07. SEARCH_SPACE_SIZE projected ~15-20 boundaries to full-space uniqueness. A
# boundary fixes pair IDENTITY and leaves the orientation bit alone: with all 31 pinnable steps
# pinned, 1,720,320 orientations survive -- the C4-oriented fiber already published at
# TR1_EIGHT_CENTURIES_MEASURED.md:333, and log2 of it is 20.71 bits no boundary count can close.
# The projection is fine for the pair-ordering object; it must not read as a route to a unique
# oriented sequence.
G14=0
_S14=${G14_DOC:-documentation/SEARCH_SPACE_SIZE.md}
_T14=${G14_TR1:-reports/TR1_EIGHT_CENTURIES_MEASURED.md}
if [ -r "$_S14" ] && [ -r "$_T14" ]; then
  if ! grep -q '1,720,320' "$_T14" 2>/dev/null; then
    echo "  [FAIL] G14: TR-1 no longer publishes the 1,720,320 fiber -- this leg measured NOTHING"; G14=1
  elif grep -qE 'projection to ~15–20|projection to ~15-20' "$_S14" 2>/dev/null \
       && ! grep -q '31 pinnable steps pinned' "$_S14" 2>/dev/null; then
    echo "  [FAIL] G14: a boundary-count projection is published without the oriented-fiber floor;"
    echo "         1,720,320 orientations survive all 31 pins = 20.71 bits no boundary count closes."
    G14=1
  else
    echo "  [ok]   G14: the boundary projection records the oriented-fiber floor it cannot cross"
  fi
else
  echo "  [FAIL] G14: cannot read $_S14 or $_T14 -- this leg measured NOTHING"; G14=1
fi

# ---- G15: a DATA-LIKE registry row must not be counted as source-stated ------------------------
# 🔴 CTA-A1, 2026-09-07. CLAIM_TO_ARTIFACT published "27 of 31 reproduce a source-stated KW value;
# 4 are KW-measured". d7 was in the 27. Its eight slots are hard-coded from King Wen's own twelve
# xiaoxi positions, so KW's 8/8 is guaranteed by construction -- shift the window by 1-5 and KW
# scores 4, 0, 1, 2, 1. LITERATURE_RULES_POPULATION_TESTS.md classifies it DATA-LIKE. Counting a
# row derived FROM King Wen as independent corroboration OF King Wen is the circularity this
# project has a standing rule about.
G15=0
_LR=${G15_POP:-documentation/LITERATURE_RULES_POPULATION_TESTS.md}
_CA=${G15_DOC:-documentation/CLAIM_TO_ARTIFACT.md}
if [ -r "$_LR" ] && [ -r "$_CA" ]; then
  if ! grep -q 'is DATA-LIKE' "$_LR" 2>/dev/null; then
    echo "  [FAIL] G15: $_LR no longer classifies any row DATA-LIKE -- this leg measured NOTHING"; G15=1
  elif grep -qE '\*\*27 of 31\*\* reproduce a source-stated' "$_CA" 2>/dev/null; then
    echo "  [FAIL] G15: 27 of 31 counted as source-stated, but d7 is classified DATA-LIKE"
    echo "         (its slots are King Wen's own; the split is 26 source-stated / 5 KW-derived)"
    G15=1
  else
    echo "  [ok]   G15: no DATA-LIKE registry row is counted as source-stated corroboration"
  fi
else
  echo "  [FAIL] G15: cannot read $_LR or $_CA -- this leg measured NOTHING"; G15=1
fi

# ---- G16: under an EXACT label, "=" may not carry an abbreviated magnitude --------------------
# 🔴 CTA-A4, 2026-09-07. CLAIM_TO_ARTIFACT defines EXACT as "computed to the last digit; a
# disagreement is a defect, not noise" -- then wrote "|C1∩C2∩C4| = 7.5706×10⁴¹", asserting
# last-digit equality for a 5-significant-figure rounding. TR-11 already had the convention right:
# "= 757,058,601,340,255,440,651,419,713,405,330,315,358,208 ≈ 7.5706×10⁴¹". Under a label whose
# whole point is that a mismatch is a DEFECT, the operator has to mean what it says.
G16=0
_CA16=${G16_DOC:-documentation/CLAIM_TO_ARTIFACT.md}
if [ -r "$_CA16" ]; then
  if ! grep -q 'computed to the last digit' "$_CA16" 2>/dev/null; then
    echo "  [FAIL] G16: $_CA16 no longer defines EXACT -- this leg measured NOTHING"; G16=1
  else
    _hits=$(grep -cE '= [0-9]+\.[0-9]+×10' "$_CA16" 2>/dev/null || true)
    if [ "${_hits:-0}" -gt 0 ]; then
      echo "  [FAIL] G16: $_hits row(s) assert '=' against an abbreviated magnitude under the EXACT label"
      G16=$_hits
    else
      echo "  [ok]   G16: abbreviated magnitudes use ≈; = is reserved for the full integer"
    fi
  fi
else
  echo "  [FAIL] G16: cannot read $_CA16 -- this leg measured NOTHING"; G16=1
fi


# ---- G17: a dead-branch claim must be scoped to its dataset and budget ------------------------
# 🔴 LB-A2, 2026-09-07 (W1/Q-434). LEADERBOARD.md labels 12 position-2 pairs "Estimated dead" on a
# 10T run that reached no ordering for them. §[11] of the SAME artifact gives 11 of those 12 positive
# first-level record counts, and its own zero set is {4, 6, 21}. The two slices measure different
# things; the unqualified label implied one was the other. GATE 53 could not see this: its universe is
# LARGE_SCALE_CAMPAIGNS.md, and the defect lives in LEADERBOARD.md.
G17=0
_LB17=${G17_DOC:-enumeration/LEADERBOARD.md}
if [ -r "$_LB17" ]; then
  if ! grep -q 'Estimated dead' "$_LB17" 2>/dev/null; then
    echo "  [FAIL] G17: $_LB17 no longer uses the 'Estimated dead' label -- this leg measured NOTHING"
    G17=1
  else
    _g17=0
    if ! grep -qF '{4, 6, 21}' "$_LB17" 2>/dev/null; then
      echo "  [FAIL] G17: the 'Estimated dead' label stands with no {4, 6, 21} zero-set qualifier"
      _g17=$((_g17+1))
    fi
    _unq=$(grep -cF 'choices lead to dead branches' "$_LB17" 2>/dev/null || true)
    if [ "${_unq:-0}" -gt 0 ]; then
      echo "  [FAIL] G17: $_unq unqualified 'choices lead to dead branches' claim(s) survive"
      _g17=$((_g17+_unq))
    fi
    if [ "$_g17" -eq 0 ]; then
      echo "  [ok]   G17: dead-branch claims are scoped, and the {4, 6, 21} zero set is stated"
    fi
    G17=$_g17
  fi
else
  echo "  [FAIL] G17: cannot read $_LB17 -- this leg measured NOTHING"; G17=1
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
# 🔴 `G3_N="${G3_N:-0}"` STOOD HERE and is deliberately gone. It was the only thing making the
# read-but-never-assigned G3 count LOOK wired: it manufactured a 0 for a leg that never set one, and
# it let the environment set the count instead. Do not re-add a default for any G<n> here or in the
# ratchet -- an unassigned count must abort under `set -u`, not read as clean. See the ratchet below.
PIN="$(dirname "$0")/gate_published_consistency.pin"
if [ ! -r "$PIN" ]; then
  echo "  [FAIL] no pin file at $PIN — an UNPINNED ratchet certifies nothing"
  echo "PUBLISHED_CONSISTENCY=FAIL"; exit 1
fi
# ---- G18: a conditional margin must not be quoted as if it were unconditional --------------------
# 🔴 RF-A2, 2026-09-07. METHODS and RETRACTED_FIGURES stated the BH margin as a supported floor,
# "≥~10×", while TR-8 -- the report they cite -- holds that BH reading CONDITIONAL on the rarity
# counting as a ledger member and names the ~5× Bonferroni margin "the firmer of the two". Every
# number is real and reproduces; what was dropped is the qualifier, so no arithmetic check could
# see it. The leg anchors on TR-8 still SAYING that, so it cannot pass by tautology if the source
# changes underneath it.
G18=0
_T8=${G18_SRC:-reports/TR8_REORDERING_REVISITED.md}
_ASSERTERS=${G18_DOCS:-"reports/METHODS.md documentation/RETRACTED_FIGURES.tsv"}
if [ -r "$_T8" ]; then
  if grep -q 'conditional' "$_T8" 2>/dev/null && grep -q 'the firmer' "$_T8" 2>/dev/null; then
    for _f in $_ASSERTERS; do
      if [ ! -r "$_f" ]; then
        echo "  [FAIL] G18: cannot read $_f -- this leg measured NOTHING"; G18=$((G18+1)); continue
      fi
      # grep -c, never grep -q on a pipe: -q exits on first match and a producer dies of SIGPIPE,
      # which under `set -o pipefail` turns a MATCH into a failed pipeline.
      if [ "$(grep -c '≥~10×' "$_f" 2>/dev/null)" -gt 0 ] \
         && [ "$(grep -c 'firmer of the two' "$_f" 2>/dev/null)" -eq 0 ]; then
        echo "  [FAIL] G18: $_f quotes the ≥~10× BH floor without TR-8's conditional"
        G18=$((G18+1))
      fi
    done
    [ "$G18" -eq 0 ] && echo "  [ok]   G18: the BH floor is quoted with its conditional wherever it is asserted"
  else
    echo "  [FAIL] G18: $_T8 no longer states the conditional/firmer wording -- this leg measured NOTHING"
    G18=1
  fi
else
  echo "  [FAIL] G18: cannot read $_T8 -- this leg measured NOTHING"; G18=1
fi

# ---- G19: an estimate with a confidence interval must say WHY it is not exact -------------------
# \U0001f534 Q-153, 2026-09-07. METHODS' canonical-quantities table carried C1-C5 at 1.3287e38 and
# |C1-C7| at 5.21e31 as bare **estimate** rows with confidence intervals and no explanation. A
# reader could reasonably infer that no exact method exists. The opposite is true: an exact
# instrument for C3 is BUILT (the Lean theorem c3_slot_decomposition, C3 = 16 + 8*G) and the run
# was priced at ~$3-5K and DELIBERATELY DECLINED. The intervals are there because the computation
# was costed and rejected, not because the answer is unknown -- and saying so is the stronger
# claim. Conflating cost with capability is the exact defect the Q-159 sweep found twice.
#
# The fix lived only in a DANGLING COMMIT (8dc7f348, on no branch, one `git gc` from gone) and was
# never published; it is tagged recovered/q153-priced-and-declined. This leg is why it cannot go
# missing again. It is deliberately shaped so no arithmetic check could substitute for it: every
# number in those rows is correct, and what was absent was a sentence.
G19=0
_M=${G19_DOC:-reports/METHODS.md}
if [ -r "$_M" ]; then
  # grep -c, never grep -q on a pipe -- see the note in G18.
  _est=$(grep -c '95% CI' "$_M" 2>/dev/null)
  if [ "$_est" -eq 0 ]; then
    echo "  [FAIL] G19: no confidence-interval row found in $_M -- this leg measured NOTHING"; G19=1
  elif [ "$(grep -c 'costed and rejected' "$_M" 2>/dev/null)" -eq 0 ] \
       || [ "$(grep -c 'priced at roughly' "$_M" 2>/dev/null)" -eq 0 ]; then
    echo "  [FAIL] G19: $_M reports $_est interval-bearing estimate(s) without saying the exact"
    echo "         computation was priced and declined -- a reader is left to infer no method exists"
    G19=1
  else
    echo "  [ok]   G19: the interval-bearing estimates ($_est) say the exact run was costed and declined"
  fi
else
  echo "  [FAIL] G19: cannot read $_M -- this leg measured NOTHING"; G19=1
fi

# shellcheck disable=SC1090
P_G1=$(awk -F= '/^G1=/{print $2}' "$PIN"); P_G2=$(awk -F= '/^G2=/{print $2}' "$PIN"); P_G3=$(awk -F= '/^G3=/{print $2}' "$PIN"); P_G4=$(awk -F= '/^G4=/{print $2}' "$PIN")
# 🔴 G5..G16 WERE ASSIGNED AND NEVER READ (found 2026-09-07). Twelve legs computed a count that
# reached neither this ratchet nor `fail` nor the verdict: they printed [FAIL] lines while the gate
# emitted PASS-AT-PIN and exit 0. Twelve checks that could not fail. They are pinned and compared now.
# \U0001f534 ONE list, three uses. Adding a leg used to mean editing THREE places in lockstep --
# this loop, the malformed-pin validation, and the ratchet pair list below. G19 was added to the
# first only, on 2026-09-07: P_G19 was populated, nothing compared it, and the leg printed [FAIL]
# while the gate emitted PASS-AT-PIN. That is precisely the "assigned and never read" defect
# recorded above for G5..G16, reproduced by the very structure that was left in place after
# fixing it. A leg cannot now half-land: it is in all three uses or in none.
GLEGS="5 6 7 8 9 10 11 12 13 14 15 16 17 18 19"
for _g in $GLEGS; do
  eval "P_G${_g}=\$(awk -F= '/^G${_g}=/{print \$2}' \"$PIN\")"
done
for _g in 1 2 3 4 $GLEGS; do
  eval "_v=\$P_G${_g}"
  case "$_v" in ''|*[!0-9]*)
    echo "  [FAIL] pin file is malformed or has no G${_g} entry"
    echo "PUBLISHED_CONSISTENCY=FAIL"; exit 1;; esac
done
echo
echo "== RATCHET vs $PIN =="
ratchet=0; tighten=0; outstanding=0; open_legs=""
# G1..G4 carry their counts in G<n>_N; G5 onward carry them in G<n>. Built from GLEGS so the
# ratchet cannot fall behind the legs that exist.
# 🔴 NO `${…:-0}` DEFAULTS HERE, DELIBERATELY, AND THIS IS THE STRUCTURAL HALF OF THE G3 FIX.
# A default is what made an unwired count invisible: G3_N was never assigned, the default supplied 0,
# and the ratchet compared 0 against a pinned 0 forever. Bare `$G<n>` under `set -u` turns the next
# such omission into an unbound-variable abort with NO verdict token -- which pre_push_gate.sh reads
# as "could not run" and BLOCKS. A leg that forgets to set its count can no longer read as clean.
_PAIRS="G1:$G1_N:$P_G1 G2:$G2_N:$P_G2 G3:$G3_N:$P_G3 G4:$G4_N:$P_G4"
for _g in $GLEGS; do
  eval "_now=\$G${_g}; _pin=\$P_G${_g}"
  _PAIRS="$_PAIRS G${_g}:${_now}:${_pin}"
done
for pair in $_PAIRS; do
  g=${pair%%:*}; rest=${pair#*:}; now=${rest%%:*}; pin=${rest##*:}
  if [ "$now" -gt 0 ]; then
    outstanding=$((outstanding+1)); open_legs="${open_legs}${open_legs:+ }${g}:${now}"
  fi
  if [ "$now" -gt "$pin" ]; then
    echo "  [FAIL] $g rose to $now from a pinned $pin — a NEW published-consistency defect"; ratchet=1
  elif [ "$now" -lt "$pin" ]; then
    echo "  [ok]   $g fell to $now from a pinned $pin — TIGHTEN THE PIN in this same commit"; tighten=1
  else
    echo "  [ok]   $g at its pinned $pin (known-open; see the pin file for why each stands)"
  fi
done
[ "$tighten" -eq 1 ] && echo "  A count fell. Leaving the pin loose lets the defect come back unseen."

# ---- WIRING SELF-CHECK: the defect class this file has now produced twice ------------------------
# 🔴 `fail` is raised by a G1–G4 leg that PRINTS a finding; `outstanding` counts the legs whose
# COUNT is non-zero. If a leg printed a finding and every count is nevertheless zero, that leg's
# count is not reaching the ratchet -- which is precisely what G5–G16 did (fixed 2026-09-07) and what
# G3 did (fixed 2026-09-08), each found by an audit rather than by the gate. The gate can now say it
# about itself. It fires as FAIL because a gate that cannot count its own findings certifies nothing.
if [ "$fail" -ne 0 ] && [ "$outstanding" -eq 0 ]; then
  echo "  [FAIL] a leg printed a finding while every leg count is zero — that count is NOT WIRED to"
  echo "         the ratchet. This is the 'read and never assigned' defect, self-detected."
  ratchet=1
fi

echo
# 🔴 THE VERDICT NAMES WHICH LEGS ARE OPEN, so the token can never be read as a stronger claim
# than it makes. Written with colons, not `=`, so these are not mistaken for emitted verdict tokens.
if [ "$outstanding" -gt 0 ]; then
  echo "  OUTSTANDING: $outstanding of 19 leg(s) non-zero — $open_legs"
  echo "               PASS is not available while any of these stands; see $PIN for why each does."
else
  echo "  OUTSTANDING: none — all 19 legs measured zero."
fi
echo
# 🔴 THREE VALUES, BECAUSE TWO WOULD LIE EITHER WAY.
#   FAIL        a count ROSE above its pin — a new defect — or the pin is missing/malformed, or a
#               leg's count is not wired to the ratchet. This is the one that must block.
#   PASS-AT-PIN no count rose, but AT LEAST ONE of the nineteen legs is non-zero. The OUTSTANDING
#               line above names them. Saying PASS here would let known-open defects read as clean;
#               saying FAIL would make every push noisy and the gate would be bypassed in a week.
#   PASS        every one of the nineteen legs measured zero. Nothing outstanding at all.
#
# 🔴 THE BOUNDARY IS "ANY LEG NON-ZERO", NOT "A G1–G4 LEG COMPLAINED" (changed 2026-09-08).
# It used to be the `fail` flag, which only G1–G4 and the disclosure-registry checks ever set, so a
# G5–G19 count sitting at a NON-ZERO PIN did not stop PASS from printing. Measured before the change:
# a tree with G1–G4 clean and G10 at its pinned 1 emitted PASS while fifteen legs printed [FAIL],
# every one of them saying "this leg measured NOTHING". PASS now means what this comment always said
# it meant. This costs nothing at the push gate: pre_push_gate.sh accepts PASS and PASS-AT-PIN
# alike, so the only verdict that can newly appear where PASS stood is the strictly more honest one.
# grep -qx the one you mean. Do not test for "PASS" as a substring: it matches PASS-AT-PIN.
if [ "$ratchet" -ne 0 ]; then
  echo "PUBLISHED_CONSISTENCY=FAIL"
elif [ "$outstanding" -ne 0 ]; then
  echo "PUBLISHED_CONSISTENCY=PASS-AT-PIN"
else
  echo "PUBLISHED_CONSISTENCY=PASS"
fi
exit 0
