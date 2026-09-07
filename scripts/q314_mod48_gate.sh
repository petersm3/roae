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
"$SOLVE" --kc-enum "$WORK/f" 2>/dev/null | grep -v '^\[' > "$WORK/walks.txt"
NW=$(grep -c . "$WORK/walks.txt"); [ "$NW" = 26112 ] || fail "n=9 gave $NW walks, expected 26112"
NT=$("$SOLVE" --kc-count "$WORK/f" 2>/dev/null | sed -n 's/^KC COUNT n=9 = \([0-9]*\)$/\1/p')
ANCHOR=$("$SOLVE" --kc-o3-unrank "$WORK/f" "$WORK/g" $((NT / 2)) 2>/dev/null | grep -E '^[0-9]+(,[0-9]+)+$' | head -1)
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

bad=0
# ---- leg 1: clean -- the gate must be PRESENT and PASS -------------------------------------
rc=$(run)
cp "$WORK/last.out" "$WORK/clean.out"      # reused by legs 3 and 4 instead of re-running
if [ "$rc" != 0 ] || ! grep -qx 'ATLAS_CONSUMER=PASS' "$WORK/last.out"; then
  echo "  [FAIL] leg 1: clean run did not pass (rc=$rc)"; bad=1
fi
if ! line48 | grep -q 'PASS'; then
  echo "  [FAIL] leg 1: the XA-48 gate is absent or not passing on a clean atlas"
  echo "         $(line48)"; bad=1
else
  echo "  [ok]   leg 1: XA-48 present and passing on the clean n=9 atlas"
fi

# ---- leg 2: the fault the OLD gate cannot see ---------------------------------------------
rc=$(run --atlas-fault q10-mod48)
if [ "$rc" = 0 ] || ! grep -q '^ATLAS_CONSUMER=FAIL' "$WORK/last.out"; then
  echo "  [FAIL] leg 2: +24 on the layer-0 flow did NOT fail the consumer (rc=$rc)"; bad=1
fi
if ! line48 | grep -q 'FAIL'; then
  echo "  [FAIL] leg 2: XA-48 did not fire on a flow that is 24-divisible but not 48-divisible"
  echo "         $(line48)"; bad=1
else
  echo "  [ok]   leg 2: XA-48 fired on the mod-48-only fault"
fi
# and the ASYMMETRY: the mod-24 gate must NOT have fired, or the fault proves nothing new
if grep -q 'XA-24.*FAIL' "$WORK/last.out"; then
  echo "  [FAIL] leg 2: the mod-24 gate ALSO fired -- this fault does not isolate XA-48,"
  echo "         so it cannot show the new gate adds coverage"; bad=1
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
grep -q 'V2-48.*PASS' "$WORK/clean.out" && echo "  [ok]   leg 3: V2-48 present and passing on the clean atlas" \
  || { echo "  [FAIL] leg 3: V2-48 absent or failing on a clean atlas: $(grep -m1 'V2-48' "$WORK/clean.out")"; bad=1; }
grep -q 'V1-16.*PASS' "$WORK/clean.out" && echo "  [ok]   leg 4: V1-16 present and passing on the clean atlas" \
  || { echo "  [FAIL] leg 4: V1-16 absent or failing on a clean atlas: $(grep -m1 'V1-16' "$WORK/clean.out")"; bad=1; }

rc=$(run --atlas-fault v2-mod48)
if line2 | grep -q 'FAIL'; then echo "  [ok]   leg 3: V2-48 fired on the mod-48-only class fault"
else echo "  [FAIL] leg 3: V2-48 did not fire on +24 to a class cell: $(line2)"; bad=1; fi
if line1 | grep -q 'FAIL'; then
  echo "  [FAIL] leg 3: V1-16 ALSO fired -- the fault does not isolate V2-48"; bad=1
else echo "  [ok]   leg 3: V1-16 did NOT fire -- the fault isolates V2-48"; fi

rc=$(run --atlas-fault v1-mod16)
if line1 | grep -q 'FAIL'; then echo "  [ok]   leg 4: V1-16 fired on the mod-16-only raw fault"
else echo "  [FAIL] leg 4: V1-16 did not fire on +8 to a raw cell: $(line1)"; bad=1; fi
if line2 | grep -q 'FAIL'; then
  echo "  [FAIL] leg 4: V2-48 ALSO fired -- the fault does not isolate V1-16"; bad=1
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
if [ "$NB0" != 2 ]; then
  echo "  [FAIL] leg 5: expected 2 V2-B0 gate lines with no walks, found $NB0 -- the vertical"
  echo "         conservation gates are absent, so nothing below measured anything"; bad=1
elif [ "$(lineb0 | grep -c 'PASS')" != 2 ]; then
  echo "  [FAIL] leg 5: a V2-B0 gate does not pass on the clean n=9 atlas"; lineb0 | sed 's/^/         /'; bad=1
else
  echo "  [ok]   leg 5: both V2-B0 gates present and passing with NO walks"
fi

rc=$(nowalks --atlas-fault v2-class-swap)
if [ "$(lineb0 | grep -c 'FAIL')" -lt 1 ]; then
  echo "  [FAIL] leg 6: v2-class-swap did NOT fire V2-B0 without walks -- the fault that moves"
  echo "         mass between distance classes is still invisible at full-31 scale"; bad=1
else
  echo "  [ok]   leg 6: V2-B0 fired on v2-class-swap with NO walks"
fi
# THE ISOLATION, asserted rather than claimed: if any PRE-EXISTING gate also fires here, these
# legs are a second opinion, not new coverage. Before they landed this run was 0 failures.
OTHER=$(grep 'FAIL' "$WORK/nw.out" | grep -v 'V2-B0' | grep -v '^ATLAS_CONSUMER=')
if [ -n "$OTHER" ]; then
  echo "  [FAIL] leg 6: a pre-existing gate ALSO fired on v2-class-swap without walks, so the"
  echo "         V2-B0 legs do not isolate the fault:"; printf '%s\n' "$OTHER" | sed 's/^/         /'; bad=1
else
  echo "  [ok]   leg 6: no pre-existing gate fired -- V2-B0 is the ONLY thing that sees this fault"
fi

[ "$bad" -eq 0 ] && echo "Q314_MOD48=PASS" || echo "Q314_MOD48=FAIL"
exit "$bad"
