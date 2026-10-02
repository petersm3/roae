#!/usr/bin/env bash
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
#
# tr12_golden_set_gate.sh — reconcile the TR-12 n=9 golden set against the battery's own row list.
#
# WHY THIS EXISTS (Q-884 GAP-2, Fable E4 Part 2, 2026-09-27; lane D31 2026-10-01). The battery
# byte-diffs each row it runs against scripts/tr12_expected/n9/<ROW_ID>.txt, and a row with no
# golden FAILs (`FAIL:no-expected-block`). Nothing checked the other direction. A row DELETED from
# the battery left its golden unread forever (an orphan), and a golden deleted together with the
# skip pin of its row read as a smaller battery with no FAIL; the fingerprint moved, a re-stamp
# followed, and the TR-12 battery was quietly one row smaller. This leg is static (no build, no
# run), so it is cheap enough to run beside every stamp and inside tests.py.
#
# THE THREE SETS.
#   ROWS     every row id the battery can open, read statically from scripts/tr12_repro.sh:
#            `row_begin ID`, `row_skip ID TOKEN`, `ladder_row ID TOK IID ITOK` (two ids) and
#            `indep_ladder_row ID TOK`, literal ids only (the three `row_begin "$id"` sites are the
#            bodies of those helper functions, whose ids come from the call sites read here).
#   GOLDENS  scripts/tr12_expected/n9/*.txt, excluding the `_`-prefixed metadata files.
#   MANIFEST the block names listed in scripts/tr12_expected/n9/_MANIFEST.txt (the regen record).
# THE RULES (each violation is named; any one makes the verdict FAIL).
#   orphan          a golden whose name is not a row id.
#   unmanifested    a golden not listed in _MANIFEST.txt; and the converse, manifest-missing,
#                   a manifest entry with no golden file (a golden deleted after regen).
#   row-no-golden   a row id with no golden, unless the row is pinned NOT RUN at n=9: one of the
#                   tokens it records (its `row_skip` token, or the `row_end` token that follows its
#                   `row_begin`) appears in _EXPECTED_SKIPS.txt. The one other exemption is
#                   b_atlas_supplied, whose expected block is DERIVED from b_scan.txt's `### atlas`
#                   section by expected_block_for(); it is exempt only while that section exists.
#   floor           fewer than ROWS_FLOOR row ids or GOLDENS_FLOOR goldens parsed is a broken parse,
#                   not a clean tree (77 row ids and 60 goldens measured on 2026-10-01).
#
# Verdict: TR12_GOLDEN_SET=PASS|FAIL (grep -qx it); receipts TR12_GOLDEN_ROWS=N TR12_GOLDENS=N.
# TR12_GOLDEN_ROOT overrides the repository root that is read, for the red tests in tests.py.
# Wired as a blocking leg of scripts/tr12_repro_gate.sh, beside the other battery-shape legs and
# BEFORE the stamp is written, so a tree with an orphan or a silently missing golden cannot be
# stamped as reproducing.
set -uo pipefail
ROOT=${TR12_GOLDEN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
BATTERY="$ROOT/scripts/tr12_repro.sh"
EXP="$ROOT/scripts/tr12_expected/n9"
ROWS_FLOOR=60
GOLDENS_FLOOR=50
fail=0
bad(){ echo "  [FAIL] $*"; fail=1; }

for f in "$BATTERY" "$EXP/_MANIFEST.txt" "$EXP/_EXPECTED_SKIPS.txt"; do
  [ -r "$f" ] || { echo "  [FAIL] $f is missing or unreadable -- nothing was reconciled"; echo "TR12_GOLDEN_SET=FAIL"; exit 1; }
done

# id<TAB>token pairs; a token of "-" means the id was seen with no token yet.
pairs=$(awk '
  { line=$0; sub(/^[[:space:]]+/, "", line) }
  line ~ /^#/ { next }
  { n=split(line, w, /[[:space:]]+/) }
  w[1]=="row_begin" && w[2] ~ /^[a-z0-9_]+$/ { cur=w[2]; print cur "\t-"; next }
  w[1]=="row_begin" { cur=""; next }
  w[1] ~ /^row_end/ && cur!="" && w[2] ~ /^TR12_[A-Z0-9_]+$/ { print cur "\t" w[2]; cur=""; next }
  w[1]=="row_skip" && w[2] ~ /^[a-z0-9_]+$/ && w[3] ~ /^TR12_[A-Z0-9_]+$/ { print w[2] "\t" w[3]; next }
  w[1]=="ladder_row" && w[2] ~ /^[a-z0-9_]+$/ { print w[2] "\t" w[3]; print w[4] "\t" w[5]; next }
  w[1]=="indep_ladder_row" && w[2] ~ /^[a-z0-9_]+$/ { print w[2] "\t" w[3]; next }
' "$BATTERY") || { echo "  [FAIL] could not parse $BATTERY"; echo "TR12_GOLDEN_SET=FAIL"; exit 1; }
rows=$(printf '%s\n' "$pairs" | cut -f1 | grep . | sort -u)
goldens=$(find "$EXP" -maxdepth 1 -type f -name '*.txt' ! -name '_*' -printf '%f\n' | sed 's/\.txt$//' | sort -u)
manifest=$(awk 'NF==2 && $1 ~ /^[0-9a-f]+$/ && $2 ~ /\.txt$/ {sub(/\.txt$/, "", $2); print $2}' "$EXP/_MANIFEST.txt" | sort -u)
skips=$(grep -oE '^TR12_[A-Z0-9_]+=' "$EXP/_EXPECTED_SKIPS.txt" | tr -d '=' | sort -u)
nrows=$(printf '%s\n' "$rows" | grep -c .)
ngold=$(printf '%s\n' "$goldens" | grep -c .)
echo "TR12_GOLDEN_ROWS=$nrows"
echo "TR12_GOLDENS=$ngold"
[ "$nrows" -ge "$ROWS_FLOOR" ] || bad "floor: only $nrows row id(s) parsed from tr12_repro.sh, below $ROWS_FLOOR -- a broken parse, not a clean battery"
[ "$ngold" -ge "$GOLDENS_FLOOR" ] || bad "floor: only $ngold golden(s) under $EXP, below $GOLDENS_FLOOR -- a moved or emptied golden set"

for g in $(comm -13 <(printf '%s\n' "$rows") <(printf '%s\n' "$goldens")); do
  bad "orphan: golden $g.txt names no row of tr12_repro.sh (a deleted or renamed row leaves it unread)"
done
for g in $(comm -23 <(printf '%s\n' "$goldens") <(printf '%s\n' "$manifest")); do
  bad "unmanifested: golden $g.txt is not listed in _MANIFEST.txt"
done
for g in $(comm -13 <(printf '%s\n' "$goldens") <(printf '%s\n' "$manifest")); do
  bad "manifest-missing: _MANIFEST.txt lists $g.txt, which is not on disk"
done
exempt=0
for r in $(comm -23 <(printf '%s\n' "$rows") <(printf '%s\n' "$goldens")); do
  toks=$(printf '%s\n' "$pairs" | awk -F'\t' -v r="$r" '$1==r && $2!="-" {print $2}' | sort -u)
  pinned=""
  for t in $toks; do grep -qx -- "$t" <<<"$skips" && pinned="$t"; done
  if [ -n "$pinned" ]; then exempt=$((exempt+1)); continue; fi
  if [ "$r" = b_atlas_supplied ] && [ -r "$EXP/b_scan.txt" ] && grep -qx '### atlas' "$EXP/b_scan.txt"; then
    exempt=$((exempt+1)); continue
  fi
  bad "row-no-golden: row $r has no golden and none of its token(s) [${toks:-none}] is pinned NOT RUN in _EXPECTED_SKIPS.txt"
done
echo "TR12_GOLDEN_EXEMPT=$exempt"
if [ "$fail" -eq 0 ]; then
  echo "  [ok] $ngold golden(s) and $nrows row id(s) reconcile ($exempt row(s) with no golden, each pinned NOT RUN at n=9 or derived)"
  echo "TR12_GOLDEN_SET=PASS"; exit 0
fi
echo "TR12_GOLDEN_SET=FAIL"; exit 1
