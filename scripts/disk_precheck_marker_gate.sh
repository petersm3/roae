#!/usr/bin/env bash
# DISK_PRECHECK_MARKER=PASS|FAIL|ERROR
#
# `--disk-precheck`'s marker leg printed "marker <path> present: PASS" for a bare stat(), under a
# comment claiming the marker "proves the mount holds the canonical disk's contents". A stat()
# cannot prove that: a zero-byte file, or a file of that name left by any other run, satisfied it.
# Disk identity is safety-critical here -- a solver-data disk was destroyed by a wrong-disk
# operation on 2026-05-06 -- so a leg that READS as an attestation while performing none is the
# wrong thing to leave in place.
#
# THE POINT OF THIS GATE IS LEGS 2 AND 3. Legs 1, 5 and 6 all pass on a version that merely
# reworded the output; only the ZERO-BYTE and JUNK markers separate "reports its content" from
# "asserts its presence". Mutant M1 is exactly that reword-only fix and it must die there.
# Leg 4 is the anti-overclaim leg: a well-formed marker with no expected digest must be REPORTED,
# never asserted -- a validator that refuses everything is a permanent FALSE dressed as rigour.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "DISK_PRECHECK_MARKER=ERROR cannot reach repo root"; exit 2; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [ERROR] $*"; echo "DISK_PRECHECK_MARKER=ERROR"; exit 2; }
[ -f solve.c ] || fail "missing solve.c"
BUILD=$(grep -m1 -E '^gcc .*solve\.c' documentation/VERIFY.md 2>/dev/null)
[ -n "$BUILD" ] || fail "no published 'gcc ... solve.c' build line in documentation/VERIFY.md"

# Compile the source AS solve.c in its own directory. Rewriting the filename inside the published
# line hits the `sha256sum solve.c` argument FIRST and silently compiles the pristine file, which
# reported every mutant SURVIVED when this idiom was first written (see q326_kc_unrank_m0_gate.sh).
build(){ local src="$1" tag="$2"; local d="$WORK/b_$tag"
  rm -rf "$d"; mkdir -p "$d" || return 2; cp "$src" "$d/solve.c" || return 2
  ( cd "$d" && eval "nice -n 10 ${BUILD/-o solve/-o $d/bin}" ) >"$WORK/build_$tag.log" 2>&1; }

if [ -n "${DISK_PRECHECK_SOLVE:-}" ]; then
  SOLVE="$DISK_PRECHECK_SOLVE"; [ -x "$SOLVE" ] || fail "DISK_PRECHECK_SOLVE=$SOLVE is not executable"
  # 🔴 EXECUTABLE IS NOT CURRENT. The else-arm compiles the committed solve.c seconds before
  # use and is safe by construction; this arm is not. DISK_PRECHECK_SOLVE names a PATH and only its
  # +x bit was checked. pre_push_gate.sh:467 hands in ./solve_167, which it built moments earlier
  # -- but a hand run `DISK_PRECHECK_SOLVE=./solve bash scripts/disk_precheck_marker_gate.sh`
  # points the gate at whatever artifact is lying in the tree, and leg 4 of this gate is the
  # ANTI-OVERCLAIM leg: a stale binary there manufactures exactly the false report it exists to
  # prevent.
  #
  # Added 2026-09-08 after scripts/resume_budget_infinity_gate.sh -- same shape -- reported FAIL,
  # an UNDERCOUNT PRESENTED AS A COMPLETE ENUMERATION, against a ./solve two days older than
  # 779fff4c, the commit that fixed exactly that. Stale -> FAIL, built from HEAD -> PASS.
  #
  # ERROR, NEVER FAIL: an unestablished subject is not a defect, and reporting it as one sends a
  # reader hunting a bug that is not there. fail() already emits DISK_PRECHECK_MARKER=ERROR/exit 2.
  #
  # Called INSIDE an `if`: lib_binary_currency.sh's foreign-sha arm ends in a `grep -vxF` that
  # exits 1 in the NORMAL case, so a bare call under this file's pipefail would abort mid-function
  # with an empty signal.
  #
  # The M1/M2 mutants below are NOT checked and must not be: they are compiled here from a
  # deliberately mutated solve.c, so a differing SOURCE_SHA is the point of them.
  . "$(cd "$(dirname "$0")" && pwd)/lib_binary_currency.sh"
  # cwd is the repo root (cd at the top of this file), so bare `solve.c` is unambiguous.
  if [ "${DISK_PRECHECK_ALLOW_STALE-}" != "1" ] && ! solve_binary_currency "$SOLVE" solve.c; then
    echo "  [ERROR] $BINCUR_MSG" >&2
    echo "          (set DISK_PRECHECK_ALLOW_STALE=1 to override, deliberately.)" >&2
    echo "DISK_PRECHECK_MARKER=ERROR"; exit 2
  fi
else
  build solve.c base || fail "published build line failed on the committed solve.c"; SOLVE="$WORK/b_base/bin"
fi

M="$WORK/mnt"; mkdir -p "$M"
GOOD=$(printf 'roae-disk-precheck-gate' | sha256sum | cut -d' ' -f1)
ZERO=0000000000000000000000000000000000000000000000000000000000000000

legs(){ # legs <solve> -> L1..L6
  local S="$1" out rc
  probe(){ SOLVE_DISK_MARKER=marker.txt "$@" "$S" --disk-precheck "$M" 1 >"$WORK/o" 2>&1; echo $?; }
  rm -f "$M/marker.txt";                        rc=$(probe env)
  grep -q 'IDENTITY NOT ESTABLISHED' "$WORK/o" && echo "L1=OK" || echo "L1=BAD"
  : > "$M/marker.txt";                          rc=$(probe env)
  { grep -q 'IDENTITY NOT ESTABLISHED' "$WORK/o" && ! grep -q 'present: PASS' "$WORK/o"; } \
      && echo "L2=OK" || echo "L2=BAD"
  echo "hello world" > "$M/marker.txt";         rc=$(probe env)
  { grep -q 'no 64-hex digest' "$WORK/o" && ! grep -q 'present: PASS' "$WORK/o"; } \
      && echo "L3=OK" || echo "L3=BAD"
  echo "$GOOD  solutions.bin" > "$M/marker.txt"; rc=$(probe env)
  { grep -q "first field $GOOD" "$WORK/o" && grep -q 'REPORTED, not asserted' "$WORK/o" \
      && ! grep -q 'IDENTITY NOT ESTABLISHED' "$WORK/o"; } && echo "L4=OK" || echo "L4=BAD"
  rc=$(probe env SOLVE_DISK_MARKER_SHA="$GOOD")
  { [ "$rc" != 5 ] && grep -q 'matches SOLVE_DISK_MARKER_SHA: PASS' "$WORK/o"; } \
      && echo "L5=OK" || echo "L5=BAD(rc=$rc)"
  rc=$(probe env SOLVE_DISK_MARKER_SHA="$ZERO")
  { [ "$rc" = 5 ] && grep -q 'MARKER MISMATCH' "$WORK/o"; } && echo "L6=OK" || echo "L6=BAD(rc=$rc)"
}

BASE=$(legs "$SOLVE")
[ "$(printf '%s\n' "$BASE" | grep -c '^L[0-9]*=')" = 6 ] \
  || fail "baseline produced $(printf '%s\n' "$BASE" | grep -c '^L[0-9]*=') leg verdicts, not 6 -- the gate measured nothing"
case "$BASE" in *=BAD*)
  printf '%s\n' "$BASE" | grep '=BAD' | sed 's/^/  [FAIL] baseline /'
  echo "DISK_PRECHECK_MARKER=FAIL"; exit 1 ;;
esac
echo "  [gate] baseline PASS on 6 legs"

# NEVER `legs ... | grep -q` under pipefail: grep -q exits at the first match and SIGPIPEs the
# producer, so the pipeline reports 141 and a KILLED mutant reads as SURVIVED. Capture, then match.
mutate(){ local name="$1" edit="$2" out
  MUT="$WORK/m.c" python3 - "$edit" <<'PY' || return 2
import os, sys
s = open("solve.c", encoding="utf-8").read()
if sys.argv[1] == "reword_only":          # keeps the new prose, drops the CONTENT test
    old = "            mk_hex = (strlen(mk_first) == 64);\n"; new = "            mk_hex = 1;\n"
elif sys.argv[1] == "assert_accepts_all": # the assertion stops comparing
    old = "            if (!mk_hex || strcmp(mk_first, want_sha) != 0) {\n"; new = "            if (0) {\n"
else: sys.exit(2)
assert s.count(old) == 1, "mutant anchor drift: " + sys.argv[1]
open(os.environ["MUT"], "w", encoding="utf-8").write(s.replace(old, new))
PY
  cmp -s solve.c "$WORK/m.c" && { echo "  [ERROR] mutant $name did not change solve.c"; return 2; }
  build "$WORK/m.c" mut || { echo "  [ERROR] mutant $name did not compile"; return 2; }
  out=$(legs "$WORK/b_mut/bin")
  [ "$(printf '%s\n' "$out" | grep -c '^L[0-9]*=')" = 6 ] \
    || { echo "  [ERROR] mutant $name produced no leg verdicts -- nothing was measured"; return 2; }
  case "$out" in *=BAD*) echo "  [gate] mutant $name killed"; return 0 ;; esac
  echo "  [FAIL] mutant $name SURVIVED -- the gate cannot see this fault"; return 1; }

K=0
for m in M1_reword_only_no_content_test:reword_only M2_assertion_accepts_any_marker:assert_accepts_all; do
  mutate "${m%%:*}" "${m##*:}"
  case $? in 0) K=$((K+1)) ;; 1) echo "DISK_PRECHECK_MARKER=FAIL"; exit 1 ;; *) echo "DISK_PRECHECK_MARKER=ERROR"; exit 2 ;; esac
done
[ "$K" = 2 ] || fail "evaluated $K mutants, expected 2"
echo "  [gate] baseline PASS on 6 legs; $K/2 mutants killed"
echo "DISK_PRECHECK_MARKER=PASS"
