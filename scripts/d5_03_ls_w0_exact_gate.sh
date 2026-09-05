#!/usr/bin/env bash
# d5_03_ls_w0_exact_gate.sh — row a0_ls_w0 must compute TR-8's pair-only null (the exact value the
# prose names), the block that gates it must pin 47/445740, and both must be able to fail.
#
# WHY. Until 2026-09-05 row a0_ls_w0 ran `--null-pair-constrained 1000000`, whose output is the
# C2|C1 and C3|C1 conditional pass rates over random pair-permutations. TR-12 section 4(a)(5) names
# "TR-8's pair-only null (10^-4 from 10^5 seeded samples)" -- P(rc4_violations <= 2 | C1) -- which
# TR-8 v1.6 made EXACT on 2026-07-21: solve.pair_null_gender_le2_exact() = 47/445740, verified two
# ways there (reports/TR8_REORDERING_REVISITED.md, revision table). TR12_LS_W0=PASS therefore
# attested a different null than the one it was named for (D5-03, WRONG-OBJECT). The row now calls
# the exact function; the MC survives as its own labelled row (a0_ls_w0_mc / TR12_LS_W0_COND_MC).
#
# WHAT IS PINNED.
#   leg 1  the live a0_ls_w0 row, extracted VERBATIM and run against the repository's solve.py,
#          reproduces the committed n9/a0_ls_w0.txt block byte for byte;
#   leg 2  that block carries `pair_null_gender_le2_exact<TAB>47/445740` -- the literal is written
#          HERE from TR-8 v1.6, not read from solve.py, so a drift in the function AND a regold to
#          match it would still fail this gate;
#   leg 3  exactly one row records TR12_LS_W0, and the MC row is labelled "NOT the TR-8 pair-only
#          null" and records a different token;
#   leg 4  a stand-in solve.py returning 47/445741 makes the row's transcript differ from the block
#          (the diff CAN see a one-unit drift in the denominator);
# plus mutants: the pre-fix row (`--null-pair-constrained` in place of the exact call), the MC row
# re-labelled to TR12_LS_W0, and a block with the value edited -- each must be caught.
#
# KNOWN LIMITATION, stated rather than papered over. Extraction anchors on the literal lines
# `row_begin a0_ls_w0` ... `row_end TR12_LS_W0 $rc` and `row_begin a0_ls_w0_mc` ... `row_end
# TR12_LS_W0_COND_MC $rc`; a refactor makes this gate FAIL with "anchors moved", never pass blind.
# Leg 1 needs python3 and ~3 s (the exact DP); without python3 the gate FAILS rather than skipping,
# because a check that cannot run must not pass.
#
# Verdict: prints exactly one D5_03_LS_W0_EXACT_GATE=<PASS|FAIL> line. Consume with grep -qx.
# D5_03_SRC overrides the source file -- ONLY so the closure check can point the gate at a file that
# lacks its target and confirm it reports FAIL.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "D5_03_LS_W0_EXACT_GATE=FAIL"; exit 40; }
SRC="${D5_03_SRC:-scripts/tr12_repro.sh}"
GOLD=scripts/tr12_expected/n9/a0_ls_w0.txt
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "D5_03_LS_W0_EXACT_GATE=FAIL"; exit 40; }
[ -f "$SRC" ] || fail "missing $SRC"
[ -f "$GOLD" ] || fail "missing the n=9 golden block $GOLD"
command -v python3 >/dev/null 2>&1 || fail "python3 is not on PATH (the row and this gate need it)"
[ -f solve.py ] || fail "solve.py missing"

# Extract the two rows. If the anchors are gone the gate ERRORS -- it never passes blind.
python3 - "$SRC" "$WORK/row.sh" "$WORK/mc.sh" <<'PY' || fail "could not extract the a0_ls_w0 / a0_ls_w0_mc rows from $SRC (anchors moved?)"
import sys
s=open(sys.argv[1],encoding='utf-8').read()
a=s.index('    row_begin a0_ls_w0\n'); b=s.index('row_end TR12_LS_W0 $rc', a)
row=s[a:b]
if 'pair_null_gender_le2_exact' not in row: raise SystemExit(3)
a=s.index('row_begin a0_ls_w0_mc\n'); b=s.index('row_end TR12_LS_W0_COND_MC $rc', a)
mc=s[a:b]
if 'null-pair-constrained' not in mc: raise SystemExit(4)
open(sys.argv[2],'w',encoding='utf-8').write(row)
open(sys.argv[3],'w',encoding='utf-8').write(mc)
PY

# leg 2: the pinned literal, from TR-8 v1.6 (2026-07-21), not from the code
grep -qx $'pair_null_gender_le2_exact\t47/445740' "$GOLD" \
  || fail "leg 2: $GOLD does not carry pair_null_gender_le2_exact<TAB>47/445740 (TR-8 v1.6's two-way-verified value)"
# leg 3: one owner for the token; the MC row is labelled and records its own token
n=$(grep -c 'row_end TR12_LS_W0 \$rc' "$SRC"); [ "$n" = 1 ] || fail "leg 3: TR12_LS_W0 is recorded by $n rows, expected exactly 1"
grep -q 'NOT the TR-8 pair-only null' "$WORK/mc.sh" || fail "leg 3: the MC row is not labelled 'NOT the TR-8 pair-only null'"
grep -q 'row_end TR12_LS_W0_COND_MC' "$SRC" || fail "leg 3: the MC row does not record TR12_LS_W0_COND_MC"

mk(){ # mk <outfile> <row.sh> <repo_root>
  { echo '#!/usr/bin/env bash'; echo 'set -u'
    echo 'row_begin(){ :; }'
    echo 'WORK=$(mktemp -d); trap '"'"'rm -rf "$WORK"'"'"' EXIT; RAW="$WORK/raw.txt"; : > "$RAW"'
    echo "REPO_ROOT='$3'"
    cat "$2"; echo 'cat "$RAW"; exit $rc'; } > "$1"
}
REPO=$(pwd)
# leg 1: the live row against the repository's solve.py reproduces the golden block
mk "$WORK/base.sh" "$WORK/row.sh" "$REPO"
bash "$WORK/base.sh" > "$WORK/base.out" 2>"$WORK/base.err"; rc=$?
[ "$rc" = 0 ] && cmp -s "$WORK/base.out" "$GOLD" || fail "leg 1: the live row (rc=$rc) does not reproduce $GOLD"
# leg 4: a stand-in solve.py off by one in the denominator must NOT reproduce the block
mkdir -p "$WORK/fake"
cat > "$WORK/fake/solve.py" <<'PY'
from fractions import Fraction
binary_hexagrams = list(range(64))
def pair_null_gender_le2_exact(): return Fraction(47, 445741)
def rc4_violations(seq): return (2, [])
PY
mk "$WORK/drift.sh" "$WORK/row.sh" "$WORK/fake"
bash "$WORK/drift.sh" > "$WORK/drift.out" 2>/dev/null
cmp -s "$WORK/drift.out" "$GOLD" && fail "leg 4: a 47/445741 stand-in reproduced the golden block -- the diff cannot see a drift"
grep -q '47/445741' "$WORK/drift.out" || fail "leg 4: the stand-in was not what the row evaluated (harness defect)"

# Mutants. Each MUST be caught by one of the legs above, re-run on the mutant.
# M1: the pre-fix row -- the MC in place of the exact call (what tr12_repro.sh ran until 2026-09-05)
python3 - "$WORK/row.sh" "$WORK/m1.row" <<'PY' || fail "mutant M1 did not apply (row shape changed?)"
import sys
s=open(sys.argv[1]).read()
a=s.index('( cd "$REPO_ROOT"'); b=s.index("' ) >>\"$RAW\"", a)+len("' ) >>\"$RAW\"")
if a<0 or b<0: raise SystemExit(3)
s=s[:a]+'( echo "# Null-model: pair-constrained random permutations"; echo "  C2 | C1 (no 5-line transitions, given C1):  42824 / 1000000  (4.282400%)" ) >>"$RAW"'+s[b:]
open(sys.argv[2],'w').write(s)
PY
mk "$WORK/m1.sh" "$WORK/m1.row" "$REPO"
bash "$WORK/m1.sh" > "$WORK/m1.out" 2>/dev/null
cmp -s "$WORK/m1.out" "$GOLD" && fail "mutant M1 (pre-fix MC row) SURVIVED -- the block cannot tell the MC from the exact null"
echo "  [gate] mutant M1_prefix_mc_row killed"
# M2: the MC row re-labelled to the parent token -> two owners of TR12_LS_W0
sed 's/row_end TR12_LS_W0_COND_MC \$rc/row_end TR12_LS_W0 $rc/' "$SRC" > "$WORK/m2.src"
cmp -s "$WORK/m2.src" "$SRC" && fail "mutant M2 did not apply"
n=$(grep -c 'row_end TR12_LS_W0 \$rc' "$WORK/m2.src"); [ "$n" = 1 ] && fail "mutant M2 (MC row records TR12_LS_W0) SURVIVED"
echo "  [gate] mutant M2_mc_relabelled_to_parent killed"
# M3: the golden block with the value edited by one unit
sed 's#47/445740#47/445741#' "$GOLD" > "$WORK/m3.gold"
cmp -s "$WORK/m3.gold" "$GOLD" && fail "mutant M3 did not apply"
if grep -qx $'pair_null_gender_le2_exact\t47/445740' "$WORK/m3.gold"; then fail "mutant M3 (edited block) SURVIVED the literal pin"; fi
cmp -s "$WORK/base.out" "$WORK/m3.gold" && fail "mutant M3 (edited block) SURVIVED the diff"
echo "  [gate] mutant M3_block_value_edited killed"
echo "  [gate] baseline PASS on 4 legs; 3/3 mutants killed"
echo "D5_03_LS_W0_EXACT_GATE=PASS"
