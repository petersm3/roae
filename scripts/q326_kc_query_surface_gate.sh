#!/usr/bin/env bash
# Q326_QUERY_SURFACE=PASS|FAIL|ERROR
#
# Q-326 items (3), (4) and (5): three ways the --kc-* query surface answered a DIFFERENT question
# than the one asked, and said nothing about it.
#
#  (3) ACCEPT-AND-IGNORE. `--kc-count DIR --kc-c3-max 387` returned the C1&C2&C4&C5 SUPERSPACE
#      count at rc=0. --kc-count/--kc-rank/--kc-member parsed --kc-c3-max and dropped it, and set
#      no emitted_record, so not even the #provenance trailer named the scope. Nothing rejected an
#      unknown option either, so a typo'd --kc-c3max was a silent no-op.
#  (4) `--kc-c3-max` was long long at the CLI and int inside kc_enum. MEASURED at n=9: T = 2^32
#      truncated to 0 and enumerated 0 walks instead of 26112, at rc=0.
#  (5) kc_parse_walk validated each SLOT and never checked the pairs form a PERMUTATION.
#      MEASURED on the pre-fix binary: 11 of 28 duplicate-pair vectors returned a POSITIVE
#      multiplicity and a repr line at rc=0, under a #provenance trailer stamping the ratified
#      convention -- a class representative for an object that is not a walk.
#
# THE POINT OF LEGS 6, 7 AND 10 is that refusing everything is not a fix. THE POINT OF LEG 11 is
# that item (5) belongs in kc_parse_walk, which all four walk-taking queries share: a fix in the
# --kc-repr branch alone passes every other leg and leaves --kc-o3-rank exposed.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "Q326_QUERY_SURFACE=ERROR cannot reach repo root"; exit 2; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [ERROR] $*"; echo "Q326_QUERY_SURFACE=ERROR"; exit 2; }
[ -f solve.c ] || fail "missing solve.c"
BUILD=$(grep -m1 -E '^gcc .*solve\.c' documentation/VERIFY.md 2>/dev/null)
[ -n "$BUILD" ] || fail "no published 'gcc ... solve.c' build line in documentation/VERIFY.md"

# Compile the source AS solve.c in its own dir: rewriting the filename in the published line hits
# the `sha256sum solve.c` argument first and silently compiles the pristine file.
build(){ local src="$1" tag="$2"; local d="$WORK/b_$tag"
  rm -rf "$d"; mkdir -p "$d" || return 2; cp "$src" "$d/solve.c" || return 2
  ( cd "$d" && eval "nice -n 10 ${BUILD/-o solve/-o $d/bin}" ) >"$WORK/build_$tag.log" 2>&1; }

if [ -n "${Q326_QS_SOLVE:-}" ]; then
  SOLVE="$Q326_QS_SOLVE"; [ -x "$SOLVE" ] || fail "Q326_QS_SOLVE=$SOLVE is not executable"
else
  build solve.c base || fail "published build line failed on the committed solve.c"; SOLVE="$WORK/b_base/bin"
fi
mkdir -p "$WORK/f" "$WORK/g"
"$SOLVE" --kc-build   "$WORK/f" --f1-pairs 9 >"$WORK/bf.log" 2>&1 || fail "--kc-build failed"
"$SOLVE" --kc-g-build "$WORK/g" --f1-pairs 9 >"$WORK/bg.log" 2>&1 || fail "--kc-g-build failed"
WALK=$("$SOLVE" --kc-unrank "$WORK/f" 0 2>/dev/null | grep -E '^[0-9]+(,[0-9]+)+$' | head -1)
[ "$(printf '%s' "$WALK" | tr ',' '\n' | grep -c .)" = 18 ] \
  || fail "could not obtain an 18-number n=9 walk -- every leg below would have compared nothing"
# Malformed vectors DERIVED from that walk, never hardcoded: slot j takes slot 0's pair, so pair 0
# repeats and pair j goes missing.
for j in 1 2 3 4 5 6 7 8; do
  python3 -c "
f='$WALK'.split(',')
f[2*$j], f[2*$j+1] = f[0], f[1]
print(','.join(f))" >> "$WORK/bad.txt"
done
[ "$(grep -c . "$WORK/bad.txt")" = 8 ] || fail "expected 8 malformed vectors, got $(grep -c . "$WORK/bad.txt")"

legs(){ # legs <solve> -> L1..L11
  local S="$1" rc out n
  q(){ "$S" "$@" >"$WORK/o" 2>"$WORK/e"; echo $?; }
  rc=$(q --kc-count "$WORK/f" --kc-c3-max 387)
  { [ "$rc" = 2 ] && [ "$(grep -c 'KC COUNT' "$WORK/o")" -eq 0 ]; } && echo "L1=OK" || echo "L1=BAD(rc=$rc)"
  rc=$(q --kc-rank "$WORK/f" "$WALK" --kc-limit 5);   [ "$rc" = 2 ] && echo "L2=OK" || echo "L2=BAD(rc=$rc)"
  rc=$(q --kc-member "$WORK/f" "$WALK" --kc-record);  [ "$rc" = 2 ] && echo "L3=OK" || echo "L3=BAD(rc=$rc)"
  rc=$(q --kc-count "$WORK/f" --kc-c3max 387)
  { [ "$rc" = 2 ] && [ "$(grep -c 'unknown option' "$WORK/e")" -gt 0 ]; } && echo "L4=OK" || echo "L4=BAD(rc=$rc)"
  rc=$(q --kc-enum "$WORK/f" --kc-c3-max abc)
  { [ "$rc" = 2 ] && [ "$(grep -c 'not a decimal integer' "$WORK/e")" -gt 0 ]; } && echo "L5=OK" || echo "L5=BAD(rc=$rc)"
  rc=$(q --kc-count "$WORK/f")
  { [ "$rc" = 0 ] && [ "$(grep -c '^KC COUNT n=9 = 26112$' "$WORK/o")" -eq 1 ]; } && echo "L6=OK" || echo "L6=BAD(rc=$rc)"
  rc=$(q --kc-unrank "$WORK/f" 0 --kc-record --kc-c3-max 0)
  { [ "$rc" = 1 ] && [ "$(grep -c 'class has no valid orientation completion' "$WORK/o")" -eq 1 ]; } \
      && echo "L7=OK" || echo "L7=BAD(rc=$rc)"
  # item (4): T = 2^32 truncated to int 0 and enumerated NOTHING. T = 2^31 does NOT discriminate
  # at n=9 -- it truncates to INT_MIN, which reads as "no filter", and no filter and an enormous
  # T are the same answer here. Measured, not assumed.
  n=$("$S" --kc-enum "$WORK/f" --kc-c3-max 4294967296 2>&1 | grep -oE 'enumerated [0-9]+' | grep -oE '[0-9]+')
  { [ -n "$n" ] && [ "$n" = 26112 ]; } && echo "L8=OK" || echo "L8=BAD(walks=${n:-none})"
  # item (5): every malformed vector refused, with the message naming the repeat
  local bad5=0 seen5=0
  while read -r B; do
    [ -n "$B" ] || continue
    seen5=$((seen5+1))
    rc=$(q --kc-repr "$WORK/f" "$B")
    { [ "$rc" != 0 ] && [ "$(grep -c 'repeats pair index' "$WORK/e")" -gt 0 ] \
      && [ "$(grep -cE '^m=[1-9]' "$WORK/o")" -eq 0 ]; } || bad5=$((bad5+1))
  done < "$WORK/bad.txt"
  { [ "$seen5" = 8 ] && [ "$bad5" = 0 ]; } && echo "L9=OK" || echo "L9=BAD($bad5/$seen5 not refused)"
  rc=$(q --kc-repr "$WORK/f" "$WALK")
  { [ "$rc" = 0 ] && [ "$(grep -cE '^m=[1-9][0-9]*	repr	' "$WORK/o")" -eq 1 ]; } \
      && echo "L10=OK" || echo "L10=BAD(rc=$rc)"
  # THE CLASS LEG: the permutation check must live in kc_parse_walk, which --kc-o3-rank shares.
  # A fix in the --kc-repr branch alone passes L9 and fails here.
  rc=$(q --kc-o3-rank "$WORK/f" "$WORK/g" "$(head -1 "$WORK/bad.txt")")
  { [ "$rc" != 0 ] && [ "$(grep -c 'repeats pair index' "$WORK/e")" -gt 0 ]; } \
      && echo "L11=OK" || echo "L11=BAD(rc=$rc)"
}

BASE=$(legs "$SOLVE")
[ "$(printf '%s\n' "$BASE" | grep -c '^L[0-9]*=')" = 11 ] \
  || fail "baseline produced $(printf '%s\n' "$BASE" | grep -c '^L[0-9]*=') leg verdicts, not 11 -- the gate measured nothing"
case "$BASE" in *=BAD*)
  printf '%s\n' "$BASE" | grep '=BAD' | sed 's/^/  [FAIL] baseline /'
  echo "Q326_QUERY_SURFACE=FAIL"; exit 1 ;;
esac
echo "  [gate] baseline PASS on 11 legs"

# NEVER `legs | grep -q` under pipefail: grep -q exits at the first match, SIGPIPEs the producer,
# the pipeline reports 141, and a KILLED mutant reads as SURVIVED. Capture, then match.
mutate(){ local name="$1" edit="$2" out
  MUT="$WORK/m.c" python3 - "$edit" <<'PY' || return 2
import os, sys
s = open("solve.c", encoding="utf-8").read()
E = sys.argv[1]
if E == "permissive_table":        # the half-fix: the block exists, the table allows everything
    old = "        int bad = saw & ~allowed;\n"; new = "        int bad = 0; (void)allowed;\n"
elif E == "atoll_not_strtoll":     # garbage silently becomes 0, which rejects the whole tree
    old = "            if (end == v || *end != '\\0' || errno == ERANGE || c3max < -1) {\n"
    new = "            if (0) {\n"
elif E == "int_narrowing":         # item (4) restored
    old = "        uint64_t emitted = kc_enum(kc, c3max, desc, kc_enum_print_cb, &ud);\n"
    new = "        uint64_t emitted = kc_enum(kc, (int)c3max, desc, kc_enum_print_cb, &ud);\n"
elif E == "mask_set_never_tested": # the half-fix: `used` is maintained but never consulted
    old = "        if ((used >> i) & 1) {\n"; new = "        if (0) {\n"
else: sys.exit(2)
assert s.count(old) == 1, "mutant anchor drift: " + E
open(os.environ["MUT"], "w", encoding="utf-8").write(s.replace(old, new))
PY
  cmp -s solve.c "$WORK/m.c" && { echo "  [ERROR] mutant $name did not change solve.c"; return 2; }
  build "$WORK/m.c" mut || { echo "  [ERROR] mutant $name did not compile"; return 2; }
  out=$(legs "$WORK/b_mut/bin")
  [ "$(printf '%s\n' "$out" | grep -c '^L[0-9]*=')" = 11 ] \
    || { echo "  [ERROR] mutant $name produced no leg verdicts -- nothing was measured"; return 2; }
  case "$out" in *=BAD*) echo "  [gate] mutant $name killed"; return 0 ;; esac
  echo "  [FAIL] mutant $name SURVIVED -- the gate cannot see this fault"; return 1; }

K=0
for m in M1_permissive_table:permissive_table M2_atoll_not_strtoll:atoll_not_strtoll \
         M3_int_narrowing:int_narrowing M4_mask_set_never_tested:mask_set_never_tested; do
  mutate "${m%%:*}" "${m##*:}"
  case $? in 0) K=$((K+1)) ;; 1) echo "Q326_QUERY_SURFACE=FAIL"; exit 1 ;; *) echo "Q326_QUERY_SURFACE=ERROR"; exit 2 ;; esac
done
[ "$K" = 4 ] || fail "evaluated $K mutants, expected 4"
echo "  [gate] baseline PASS on 11 legs; $K/4 mutants killed"
echo "Q326_QUERY_SURFACE=PASS"
