#!/usr/bin/env bash
# Q326_UNRANK_M0=PASS|FAIL|ERROR
#
# Q-326 item (1). `--kc-unrank DIR R --kc-record` printed the class representative
# UNCONDITIONALLY. kc_class_repr returns m == 0 to mean "no valid orientation completion",
# and on every one of its m == 0 exits it leaves `repr` UNWRITTEN. So the record line was
# built from uninitialised stack, indexing partner[64] with bytes up to 255 -- out of bounds
# -- and it exited rc = 0 with a #provenance trailer stamping the garbage as conformant.
# The --kc-class sibling has always guarded m == 0; this path never did.
#
# THE POINT OF THIS GATE IS LEG 3. A guard that sets rc = 1 and still prints repr passes
# legs 1 and 2 and is still reading uninitialised memory; only the run-to-run byte-identity
# check sees it. Mutant M2 IS that half-fix, and it must die here. A gate whose legs all fall
# to the same fault has one leg, not four.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "Q326_UNRANK_M0=ERROR cannot reach repo root"; exit 2; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [ERROR] $*"; echo "Q326_UNRANK_M0=ERROR"; exit 2; }

[ -f solve.c ] || fail "missing solve.c"
BUILD=$(grep -m1 -E '^gcc .*solve\.c' documentation/VERIFY.md 2>/dev/null)
[ -n "$BUILD" ] || fail "no published 'gcc ... solve.c' build line in documentation/VERIFY.md"

# \U0001f534 Compile the source AS solve.c in its own directory -- do NOT rewrite the filename
# inside the published build line. That line reads
#     -DSOURCE_SHA="\"$(sha256sum solve.c | ...)\"" -o solve solve.c
# so `${line/solve.c/$src}` hits the sha256sum argument FIRST and leaves the compiled input as
# the pristine solve.c. Measured 2026-09-07: every mutant silently compiled the FIXED source and
# was reported SURVIVED. A harness that builds the wrong thing and still prints a verdict is the
# exact defect this gate exists to catch, so it now proves what it built (see build_verified).
build(){ # build <src-file> <tag>  -> binary at $WORK/b_<tag>/bin
  # NOTE: `local` is a BUILTIN, so all its arguments are word-expanded BEFORE any of its
  # assignments take effect -- `local tag="$2" d="$WORK/b_$tag"` expands $tag while it is still
  # unset, which under `set -u` aborts the whole gate. Two statements, not one.
  local src="$1" tag="$2"
  local d="$WORK/b_$tag"
  rm -rf "$d"; mkdir -p "$d" || return 2
  cp "$src" "$d/solve.c" || return 2
  ( cd "$d" && eval "nice -n 10 ${BUILD/-o solve/-o $d/bin}" ) >"$WORK/build_$tag.log" 2>&1
}
build_verified(){ # build <src> <tag>, then PROVE the binary carries that source's sha
  local src="$1" tag="$2" want got
  build "$src" "$tag" || return 1
  want=$(sha256sum "$src" | cut -d' ' -f1)
  got=$("$WORK/b_$tag/bin" --kc-unrank "$WORK/f" 0 --kc-record 2>/dev/null \
        | sed -n 's/.*source_sha=\([0-9a-f]*\).*/\1/p' | head -1)
  [ -n "$got" ] && [ "$got" = "$want" ] || {
    echo "  [ERROR] $tag: binary reports source_sha=${got:-<none>}, source hashes to $want"
    return 2; }
  return 0
}
# The baseline binary may be handed in by tr12_repro_gate.sh (same contract as Q314_SOLVE), so the
# pre-push run pays for ONE build of the committed source instead of two. The mutants are always
# built here -- that is the whole gate, and a handed-in binary cannot carry a mutation.
if [ -n "${Q326_SOLVE:-}" ]; then
  SOLVE="$Q326_SOLVE"; [ -x "$SOLVE" ] || fail "Q326_SOLVE=$SOLVE is not executable"
else
  build solve.c base || fail "published build line failed on the committed solve.c"
  SOLVE="$WORK/b_base/bin"
fi
mkdir -p "$WORK/f"
"$SOLVE" --kc-build "$WORK/f" --f1-pairs 9 >"$WORK/bf.log" 2>&1 || fail "--kc-build failed"
BASE_SHA=$(sha256sum solve.c | cut -d' ' -f1)
BASE_GOT=$("$SOLVE" --kc-unrank "$WORK/f" 0 --kc-record 2>/dev/null \
           | sed -n 's/.*source_sha=\([0-9a-f]*\).*/\1/p' | head -1)
[ "$BASE_GOT" = "$BASE_SHA" ] || fail "baseline binary reports source_sha=${BASE_GOT:-<none>}, solve.c hashes to $BASE_SHA"

# --- the four legs, run against any binary -----------------------------------------------
# Each echoes one KEY=value token. The caller greps for them; output SHAPE is never the
# verdict (a crashed binary prints nothing, and nothing must never read as agreement).
legs(){ # legs <solve>  -> prints L1=.. L2=.. L3=.. L4=..
  local S="$1" a b rc
  # the binary's OWN status, taken from a bare run -- never from a pipeline, where it would be
  # grep's status instead.
  "$S" --kc-unrank "$WORK/f" 0 --kc-record --kc-c3-max 0 >/dev/null 2>&1; rc=$?
  a=$("$S" --kc-unrank "$WORK/f" 0 --kc-record --kc-c3-max 0 2>/dev/null | grep '^record')
  b=$("$S" --kc-unrank "$WORK/f" 0 --kc-record --kc-c3-max 0 2>/dev/null | grep '^record')
  [ "$rc" = 1 ]                                                  && echo "L1=OK" || echo "L1=BAD(rc=$rc)"
  [ "$a" = "record	m=0	(class has no valid orientation completion)" ] \
                                                                 && echo "L2=OK" || echo "L2=BAD"
  [ -n "$a" ] && [ "$a" = "$b" ]                                 && echo "L3=OK" || echo "L3=BAD"
  local n; n=$("$S" --kc-unrank "$WORK/f" 0 --kc-record 2>/dev/null \
               | sed -n 's/^record\tm=\([0-9]*\)\t.*/\1/p')
  [ -n "$n" ] && [ "$n" -gt 0 ] 2>/dev/null                       && echo "L4=OK" || echo "L4=BAD"
}

# \U0001f534 NEVER `legs ... | grep -q`. Under `pipefail`, grep -q exits at the first match and
# SIGPIPEs the producer, so the pipeline reports 141 and the match reads as NO match -- which
# inverts every mutant verdict below. Measured here on 2026-09-07: M1 reported SURVIVED while
# it was in fact killed. Capture first, match the string second.
BASE=$(legs "$SOLVE")
NL=$(printf '%s\n' "$BASE" | grep -c '^L[0-9]*=')
[ "$NL" = 4 ] || fail "baseline produced $NL leg verdicts, not 4 -- the gate measured nothing"
case "$BASE" in *=BAD*)
  printf '%s\n' "$BASE" | grep '=BAD' | sed 's/^/  [FAIL] baseline /'
  echo "Q326_UNRANK_M0=FAIL"; exit 1 ;;
esac
echo "  [gate] baseline PASS on 4 legs"

# --- mutants -----------------------------------------------------------------------------
# M1 restores the exact pre-fix block. M2 is the HALF-FIX: rc = 1, repr still printed.
mutate(){ # mutate <name> <python-fragment-file> -> 0 if the mutant was KILLED
  local name="$1" py="$2"
  python3 "$py" solve.c "$WORK/m.c" || return 2
  cmp -s solve.c "$WORK/m.c" && { echo "  [ERROR] mutant $name did not change solve.c"; return 2; }
  build_verified "$WORK/m.c" mut
  case $? in 0) ;; *) echo "  [ERROR] mutant $name did not compile as itself"; return 2 ;; esac
  local out; out=$(legs "$WORK/b_mut/bin")
  [ "$(printf '%s\n' "$out" | grep -c '^L[0-9]*=')" = 4 ] || {
    echo "  [ERROR] mutant $name produced no leg verdicts -- nothing was measured"; return 2; }
  case "$out" in *=BAD*) echo "  [gate] mutant $name killed"; return 0 ;; esac
  echo "  [FAIL] mutant $name SURVIVED -- the gate cannot see this fault"; return 1
}

cat > "$WORK/m1.py" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
i=s.index('if (m == 0) {\n                    printf("record\\tm=0')
j=s.index('                }\n            }\n',i)+len('                }\n')
old='''                if (m == 0) {
                    printf("record\\tm=0\\t(class has no valid orientation completion)\\n");
                    rc = 1;
                } else {
                    printf("record\\tm=%llu\\t", (unsigned long long)m);
                    kc_print_walk(kc, repr, stdout);
                }
'''
assert s[i-16:j]==old, "M1 anchor drift"
new='''                printf("record\\tm=%llu\\t", (unsigned long long)m);
                kc_print_walk(kc, repr, stdout);
'''
open(sys.argv[2],'w',encoding='utf-8').write(s[:i-16]+new+s[j:])
PY
cat > "$WORK/m2.py" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
old='''                if (m == 0) {
                    printf("record\\tm=0\\t(class has no valid orientation completion)\\n");
                    rc = 1;
                } else {'''
new='''                if (m == 0) {
                    rc = 1;
                }
                {'''
assert s.count(old)==1, "M2 anchor drift"
open(sys.argv[2],'w',encoding='utf-8').write(s.replace(old,new))
PY

K=0
for m in M1_guard_removed:m1 M2_rc_set_but_repr_still_printed:m2; do
  mutate "${m%%:*}" "$WORK/${m##*:}.py" || { [ $? = 2 ] && { echo "Q326_UNRANK_M0=ERROR"; exit 2; }; echo "Q326_UNRANK_M0=FAIL"; exit 1; }
  K=$((K+1))
done
[ "$K" = 2 ] || fail "evaluated $K mutants, expected 2"
echo "  [gate] baseline PASS on 4 legs; $K/2 mutants killed"
echo "Q326_UNRANK_M0=PASS"
