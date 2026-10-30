#!/usr/bin/env bash
# Q314_MOD48=PASS|FAIL|ERROR
#
# Q-314 item (1): the atlas is checked for mod-24 divisibility, but the free G48 action makes
# the complete raw sequences divisible by 48. The shipped gate read a PRECOMPUTED `mod24_ok`
# column -- i.e. it checked the emitter against itself -- and stopped at 24.
#
# THE POINT OF THIS GATE IS THE SECOND LEG, not the first. A new check that only fires on
# faults the old check already catches has added nothing. `--atlas-fault q10-mod48` adds
# _ATLAS_ORBIT (=24) to the layer-0 flow: still divisible by 24, no longer by 48. It is
# INVISIBLE to the mod-24 gate and fatal to XA-48. That asymmetry is the whole claim.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "Q314_MOD48=ERROR cannot reach repo root"; exit 2; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [ERROR] $*"; echo "Q314_MOD48=ERROR"; exit 2; }

# the binary: the PUBLISHED build line, or the one the caller already built (same contract as
# scripts/q422_ratio_columns_gate.sh, so tr12_repro_gate.sh can hand us its build instead of
# paying for a second one).
if [ -n "${Q314_SOLVE:-}" ]; then
  SOLVE="$Q314_SOLVE"; [ -x "$SOLVE" ] || fail "Q314_SOLVE=$SOLVE is not executable"
  # 🔴 EXECUTABLE IS NOT CURRENT. The else-arm below is safe BY CONSTRUCTION -- it compiles
  # the committed solve.c seconds before use. This arm is not: Q314_SOLVE names a PATH, and the
  # only thing checked above is the +x bit. tr12_repro_gate.sh passes a binary it just built, but
  # `Q314_SOLVE=./solve bash scripts/q314_mod48_gate.sh` by hand points the gate at whatever
  # artifact is lying in the tree. Added 2026-09-08 after scripts/resume_budget_infinity_gate.sh
  # -- same `${VAR:-}`-names-a-path shape -- reported FAIL, i.e. AN UNDERCOUNT PRESENTED AS A
  # COMPLETE ENUMERATION, against a ./solve two days older than 779fff4c, the commit that fixed
  # exactly that. Measured both ways that night: stale -> FAIL, built from HEAD -> PASS.
  #
  # ERROR, NEVER FAIL: an unestablished subject is not a defect, and reporting it as one sends a
  # reader hunting a bug that is not there. fail() here already emits Q314_MOD48=ERROR / exit 2.
  #
  # Called INSIDE an `if`. lib_binary_currency.sh's foreign-sha arm ends in a `grep -vxF` that
  # exits 1 in the NORMAL case; a bare call under this file's pipefail would abort the function
  # with an empty signal. Never call solve_binary_currency outside a condition.
  #
  # The mutants below are NOT checked, and must not be: they are built here from a DELIBERATELY
  # mutated solve.c, so their SOURCE_SHA is supposed to differ. Staleness is a defect in the
  # subject and a requirement in the control.
  . "$(cd "$(dirname "$0")" && pwd)/lib_binary_currency.sh"
  # cwd is the repo root (the cd at the top of this file), so `solve.c` is unambiguous here.
  if [ "${Q314_ALLOW_STALE-}" != "1" ] && ! solve_binary_currency_strict "$SOLVE" solve.c; then
    echo "  [ERROR] $BINCUR_MSG" >&2
    echo "          (set Q314_ALLOW_STALE=1 to override, deliberately.)" >&2
    echo "Q314_MOD48=ERROR"; exit 2
  fi
else
  [ -f solve.c ] || fail "missing solve.c"
  BUILD=$(grep -m1 -E '^gcc .*solve\.c' documentation/VERIFY.md 2>/dev/null)
  [ -n "$BUILD" ] || fail "no published 'gcc ... solve.c' build line in documentation/VERIFY.md"
  ( eval "${BUILD/-o solve/-o $WORK/solve}" ) >"$WORK/build.log" 2>&1 || fail "published build line failed"
  SOLVE="$WORK/solve"
fi

mkdir -p "$WORK/f" "$WORK/g" "$WORK/t"
"$SOLVE" --kc-build   "$WORK/f" --f1-pairs 9 >"$WORK/bf.log" 2>&1 || fail "--kc-build failed"
"$SOLVE" --kc-g-build "$WORK/g" --f1-pairs 9 >"$WORK/bg.log" 2>&1 || fail "--kc-g-build failed"
"$SOLVE" --kc-t-build "$WORK/f" "$WORK/t"    >"$WORK/bt.log" 2>&1 || fail "--kc-t-build failed"
"$SOLVE" --kc-scan "$WORK/f" "$WORK/g" "$WORK/atlas.json" --kc-tdir "$WORK/t" --kc-raw \
    >"$WORK/scan.log" 2>&1 || fail "--kc-scan failed"
# Each producer's own exit status is part of its answer (Codex, gpt-6-astra, F05-013#7): output
# followed by a nonzero exit is a failed run, not a universe.
"$SOLVE" --kc-enum "$WORK/f" 2>/dev/null > "$WORK/enum.raw" || fail "--kc-enum exited nonzero"
grep -v '^\[' "$WORK/enum.raw" > "$WORK/walks.txt"
NW=$(grep -c . "$WORK/walks.txt"); [ "$NW" = 26112 ] || fail "n=9 gave $NW walks, expected 26112"
NT=$("$SOLVE" --kc-count "$WORK/f" 2>/dev/null) || fail "--kc-count exited nonzero"
NT=$(printf '%s\n' "$NT" | sed -n 's/^KC COUNT n=9 = \([0-9]*\)$/\1/p')
ANCHOR=$("$SOLVE" --kc-o3-unrank "$WORK/f" "$WORK/g" $((NT / 2)) 2>/dev/null) || fail "--kc-o3-unrank exited nonzero"
ANCHOR=$(printf '%s\n' "$ANCHOR" | grep -E '^[0-9]+(,[0-9]+)+$' | awk 'NR==1')
[ -n "$ANCHOR" ] || fail "could not materialise the O3-midpoint anchor walk"
"$SOLVE" --kc-o3-rank "$WORK/f" "$WORK/g" "$ANCHOR" --kc-trace --kc-bracket \
    > "$WORK/q3_profile.txt" 2>&1 || fail "--kc-o3-rank failed"

run(){ # run [extra args...] -> rc; transcript in $WORK/last.out
  rm -rf "$WORK/keep"; mkdir -p "$WORK/keep"
  python3 solve.py --atlas-selftest "$WORK/atlas.json" --atlas-walks "$WORK/walks.txt" \
      --atlas-q3-trace "$WORK/q3_profile.txt" --atlas-keep "$WORK/keep" "$@" \
      > "$WORK/last.out" 2>&1
  echo $?
}
line48(){ grep -m1 'XA-48' "$WORK/last.out"; }
# gstat <transcript> <exact gate name> -> PASS | FAIL | NONE | MULTI | OTHER. The STATUS FIELD, read
# where solve.py's gate() prints it ("[atlas-consumer] %-62s %s%s": the name, spaces, PASS, or FAIL
# and then "  detail"), never a PASS/FAIL substring anywhere on the line (Codex, gpt-6-astra,
# F05-013#8: "NOT_PASS", "NOT_FAIL" and a status followed by explanatory text naming the other one
# all satisfied the substring tests).
gstat(){
  awk -v n="[atlas-consumer] $2" '
    index($0, n " ") == 1 || $0 == n { c++; r = substr($0, length(n) + 1); sub(/^ +/, "", r)
      if (r == "PASS") s = "PASS"; else if (r == "FAIL" || index(r, "FAIL  ") == 1) s = "FAIL"; else s = "OTHER" }
    END { if (c == 0) print "NONE"; else if (c > 1) print "MULTI"; else print s }' "$1"
}
XA24="Q10a/XA-24: N_total and every layer flow divisible by 24"
XA48="XA-48: N_total and every layer flow divisible by 48 (re-derived, not a column)"
V248="V2-48: every distance-class cell divisible by 48"
V116="V1-16: every RAW per-pair cell divisible by 16"
B0A="V2-B0: every distance class's column sums to a whole multiple of N_total"
B0B="V2-B0: the C5 boundary budget sums to n (one boundary per layer, per walk)"
# a fault run must END as the consumer's documented failure: rc 1 and the whole-line token.
faulted(){ [ "$1" = 1 ] && grep -qx 'ATLAS_CONSUMER=FAIL' "$2"; }

bad=0
# ---- leg 1: clean -- the gate must be PRESENT and PASS -------------------------------------
rc=$(run)
cp "$WORK/last.out" "$WORK/clean.out"      # reused by legs 3 and 4 instead of re-running
if [ "$rc" != 0 ] || ! grep -qx 'ATLAS_CONSUMER=PASS' "$WORK/last.out"; then
  echo "  [FAIL] leg 1: clean run did not pass (rc=$rc)"; bad=1
fi
if [ "$(gstat "$WORK/last.out" "$XA48")" != PASS ]; then
  echo "  [FAIL] leg 1: the XA-48 gate is absent or not passing on a clean atlas"
  echo "         $(line48)"; bad=1
else
  echo "  [ok]   leg 1: XA-48 present and passing on the clean n=9 atlas"
fi

# ---- leg 2: the fault the OLD gate cannot see ---------------------------------------------
rc=$(run --atlas-fault q10-mod48)
if ! faulted "$rc" "$WORK/last.out"; then
  echo "  [FAIL] leg 2: +24 on the layer-0 flow did NOT fail the consumer (rc=$rc)"; bad=1
fi
if [ "$(gstat "$WORK/last.out" "$XA48")" != FAIL ]; then
  echo "  [FAIL] leg 2: XA-48 did not fire on a flow that is 24-divisible but not 48-divisible"
  echo "         $(line48)"; bad=1
else
  echo "  [ok]   leg 2: XA-48 fired on the mod-48-only fault"
fi
# and the ASYMMETRY: the mod-24 gate must NOT have fired, or the fault proves nothing new
if [ "$(gstat "$WORK/last.out" "$XA24")" != PASS ]; then
  echo "  [FAIL] leg 2: the mod-24 gate ALSO fired -- this fault does not isolate XA-48,"
  echo "         so it cannot show the new gate adds coverage"; bad=1
elif ! grep -q 'XA-24.*PASS' "$WORK/last.out"; then
  # G5a (Codex F05-013#9): isolation needs the comparison gate to have RUN and passed; a deleted
  # XA-24 line also "did not fire".
  echo "  [FAIL] leg 2: the mod-24 gate printed no PASS line on the fault run -- isolation is not shown"; bad=1
else
  echo "  [ok]   leg 2: the mod-24 gate did NOT fire -- the fault isolates XA-48"
fi

# ---- legs 3 and 4: item 2's stabiliser gates, each with an ISOLATING fault ------------------
# The pre-existing faults cannot test these. v2-class-swap SWAPS two class masses, and a swap
# preserves divisibility exactly; v1-drop-pair sets a cell to 0, and 0 is divisible by everything.
# So each new gate needs its own fault or it ships untestable.
line2(){ grep -m1 'V2-48' "$WORK/last.out"; }
line1(){ grep -m1 'V1-16' "$WORK/last.out"; }

# The clean transcript was already produced by leg 1 and saved; do NOT pay for a second one.
# This gate runs inside tr12_repro_gate.sh on every push, so each redundant consumer invocation
# is charged to every push for the life of the gate.
[ "$(gstat "$WORK/clean.out" "$V248")" = PASS ] && echo "  [ok]   leg 3: V2-48 present and passing on the clean atlas" \
  || { echo "  [FAIL] leg 3: V2-48 absent or failing on a clean atlas: $(grep -m1 'V2-48' "$WORK/clean.out")"; bad=1; }
[ "$(gstat "$WORK/clean.out" "$V116")" = PASS ] && echo "  [ok]   leg 4: V1-16 present and passing on the clean atlas" \
  || { echo "  [FAIL] leg 4: V1-16 absent or failing on a clean atlas: $(grep -m1 'V1-16' "$WORK/clean.out")"; bad=1; }

rc=$(run --atlas-fault v2-mod48)
faulted "$rc" "$WORK/last.out" || { echo "  [FAIL] leg 3: the v2-mod48 run did not end as ATLAS_CONSUMER=FAIL, rc 1 (rc=$rc)"; bad=1; }
if [ "$(gstat "$WORK/last.out" "$V248")" = FAIL ]; then echo "  [ok]   leg 3: V2-48 fired on the mod-48-only class fault"
else echo "  [FAIL] leg 3: V2-48 did not fire on +24 to a class cell: $(line2)"; bad=1; fi
if [ "$(gstat "$WORK/last.out" "$V116")" != PASS ]; then
  echo "  [FAIL] leg 3: V1-16 ALSO fired -- the fault does not isolate V2-48"; bad=1
elif ! line1 | grep -c 'PASS' >/dev/null; then echo "  [FAIL] leg 3: V1-16 printed no PASS line on the fault run -- isolation is not shown (G5a)"; bad=1
else echo "  [ok]   leg 3: V1-16 did NOT fire -- the fault isolates V2-48"; fi

rc=$(run --atlas-fault v1-mod16)
faulted "$rc" "$WORK/last.out" || { echo "  [FAIL] leg 4: the v1-mod16 run did not end as ATLAS_CONSUMER=FAIL, rc 1 (rc=$rc)"; bad=1; }
if [ "$(gstat "$WORK/last.out" "$V116")" = FAIL ]; then echo "  [ok]   leg 4: V1-16 fired on the mod-16-only raw fault"
else echo "  [FAIL] leg 4: V1-16 did not fire on +8 to a raw cell: $(line1)"; bad=1; fi
if [ "$(gstat "$WORK/last.out" "$V248")" != PASS ]; then
  echo "  [FAIL] leg 4: V2-48 ALSO fired -- the fault does not isolate V1-16"; bad=1
elif ! line2 | grep -c 'PASS' >/dev/null; then echo "  [FAIL] leg 4: V2-48 printed no PASS line on the fault run -- isolation is not shown (G5a)"; bad=1
else echo "  [ok]   leg 4: V2-48 did NOT fire -- the fault isolates V1-16"; fi

# ---- legs 5 and 6: item 3's VERTICAL conservation, tested WITHOUT walks --------------------
# Every other leg above runs with --atlas-walks. That is the configuration that CANNOT EXIST at
# n=31: brute force means enumerating all 26,112 walks explicitly. So the legs below deliberately
# run with NO walks, because that is the only configuration the full-31 numbers are produced in,
# and it is the configuration in which v2-class-swap was previously invisible.
nowalks(){ # same as run(), minus --atlas-walks -- transcript in $WORK/nw.out
  python3 solve.py --atlas-selftest "$WORK/atlas.json" \
      --atlas-q3-trace "$WORK/q3_profile.txt" "$@" > "$WORK/nw.out" 2>&1
  echo $?
}
lineb0(){ grep 'V2-B0' "$WORK/nw.out"; }

rc=$(nowalks)
NB0=$(lineb0 | grep -c .)
# The clean no-walks run's documented end is rc 1 with ATLAS_CONSUMER=SKIP:no-brute-force-walks
# (measured 2026-10-22); two PASS lines followed by a kill (137) is not that end.
if [ "$rc" != 1 ] || ! grep -qx 'ATLAS_CONSUMER=SKIP:no-brute-force-walks' "$WORK/nw.out"; then
  echo "  [FAIL] leg 5: the clean no-walks run did not end as ATLAS_CONSUMER=SKIP:no-brute-force-walks, rc 1 (rc=$rc)"; bad=1
elif [ "$NB0" != 2 ]; then
  echo "  [FAIL] leg 5: expected 2 V2-B0 gate lines with no walks, found $NB0 -- the vertical"
  echo "         conservation gates are absent, so nothing below measured anything"; bad=1
elif [ "$(gstat "$WORK/nw.out" "$B0A")" != PASS ] || [ "$(gstat "$WORK/nw.out" "$B0B")" != PASS ]; then
  echo "  [FAIL] leg 5: a V2-B0 gate does not pass on the clean n=9 atlas"; lineb0 | sed 's/^/         /'; bad=1
else
  echo "  [ok]   leg 5: both V2-B0 gates present and passing with NO walks"
fi

rc=$(nowalks --atlas-fault v2-class-swap)
if ! faulted "$rc" "$WORK/nw.out"; then
  echo "  [FAIL] leg 6: the v2-class-swap run did not end as ATLAS_CONSUMER=FAIL, rc 1 (rc=$rc)"; bad=1
elif [ "$(gstat "$WORK/nw.out" "$B0A")" != FAIL ] && [ "$(gstat "$WORK/nw.out" "$B0B")" != FAIL ]; then
  echo "  [FAIL] leg 6: v2-class-swap did NOT fire V2-B0 without walks -- the fault that moves"
  echo "         mass between distance classes is still invisible at full-31 scale"; bad=1
else
  echo "  [ok]   leg 6: V2-B0 fired on v2-class-swap with NO walks"
fi
# THE ISOLATION, asserted rather than claimed: if any PRE-EXISTING gate also fires here, these
# legs are a second opinion, not new coverage. Before they landed this run was 0 failures.
# The selftest's own GATE lines are what this isolates. Since 2026-10-22 (push group G5b, CX-35V-C) the selftest also
# prints each query verdict its run wrote as FAIL ("[atlas-consumer] query verdict K=V written by this run ..."); those
# are the consumer's verdicts, not selftest gates, so they are outside this check.
OTHER=$(grep 'FAIL' "$WORK/nw.out" | grep -v 'V2-B0' | grep -v '^ATLAS_CONSUMER=' | grep -v '^\[atlas-consumer\] query verdict ')
if [ -n "$OTHER" ]; then
  echo "  [FAIL] leg 6: a pre-existing gate ALSO fired on v2-class-swap without walks, so the"
  echo "         V2-B0 legs do not isolate the fault:"; printf '%s\n' "$OTHER" | sed 's/^/         /'; bad=1
else
  echo "  [ok]   leg 6: no pre-existing gate fired -- V2-B0 is the ONLY thing that sees this fault"
fi

[ "$bad" -eq 0 ] && echo "Q314_MOD48=PASS" || echo "Q314_MOD48=FAIL"
exit "$bad"
