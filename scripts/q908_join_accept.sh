#!/usr/bin/env bash
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
# ============================================================================
# q908_join_accept.sh — acceptance for `verify --c67-join` (Q-908, 2026-09-30)
#
# `verify --c67-join` computes the slot-pinned count (pair-slots S..S+w-1 hold
# given pairs, orientation free — the --ie-pin semantics) from STORED ladder
# bytes: f layer S-1 joined to g layer S+w-1 across the pinned steps. This
# script builds small ladders with solve.c and requires the join to agree,
# digit for digit, with the two ladder-free instruments already in verify.c:
#   --ie-count --ie-pin ... --ie-no-quotient   (signed IE transfer walk)
#   --ie-count --ie-pin ... --ie-brute         (explicit permutation DFS)
#
# Per n (default "9 10"; reduced instances via --f1-pairs, the ie spec is the
# same orbit union solve.c's table resolves, and the ie budget is the
# manifest's b0 passed with --ie-b0 so both sides count the same instance):
#   W1  the C6/C7-equivalent window: slots n-7..n-4 (at n=31 that is 24..27),
#       slot s pinned to the s-th smallest pair of the instance (at n=31 the
#       pairs are 1..31, so this IS King Wen's pair at its own slot)
#   W2..W6  five more 4-slot windows / pin choices, incl. slot 1 (f layer 0)
#       and the last slot (g layer n, the seed)
#   T3 + pin-sum  a 3-slot window, and the identity: its count == the sum over
#       every remaining pair P of the 4-slot window with P at the next slot
#   DUP  one pair pinned at two slots: join 0 (by definition) and ie 0
#   every window must match ie AND brute exactly; at least 2 of W1..W6 must be
#   nonzero per n (a vacuous all-zero agreement is not acceptance). A planned window that is
#   empty keeps its three-way check, then its last pin is searched for a nonzero window of the
#   same shape (orchestrator 2026-09-30: n=9 had only W1 nonzero among the planned six).
# Negative controls (first n only), each required to come out red:
#   doubled g layer    every value of g layer b x2 -> the count doubles
#                      exactly, and --join-expect <old> gives C67_JOIN=FAIL
#   one g entry +1     some single corrupted g entry changes the count
#   wrong pin          a pin swap whose ie count differs -> C67_JOIN=FAIL
#   truncated g layer  -> C67_JOIN=REFUSED, rc 2
#   missing f layer    -> C67_JOIN=REFUSED, rc 2
#   pair not in instance / non-consecutive slots / --join-c6c7 below n=31
#                      -> C67_JOIN=REFUSED with the named reason, rc 2
#
# Usage: scripts/q908_join_accept.sh
#   env: SOLVE_BIN=./solve VERIFY_BIN=./verify Q908_NS="9 10" Q908_WORK=/path
#        Q908_ALLOW_STALE=1 (deliberately skip the solve binary currency check)
# Build: gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz
#        gcc -O2 -Wall -Wextra -o verify verify.c -lz -lpthread -lm
# Verdict (whole lines): Q908_JOIN_ACCEPT=PASS | FAIL | ERROR
#   (rc 0 / 1 / 2). ERROR = not runnable (missing or stale binary, build
#   failure) — never reported as FAIL.
# Cost: seconds at n=9 and n=10; a few MB of scratch.
# ============================================================================
set -uo pipefail

SOLVE="${SOLVE_BIN:-./solve}"
VERIFY="${VERIFY_BIN:-./verify}"
NS="${Q908_NS:-9 10}"
WORK="${Q908_WORK:-$(mktemp -d /tmp/q908_join_XXXXXX)}"
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$WORK"

fails=0
checks=0
ok()   { echo "  ok   $*"; checks=$((checks + 1)); }
bad()  { echo "  FAIL $*"; fails=$((fails + 1)); }
error() {
  echo "ERROR: $*"
  echo "Q908_JOIN_ACCEPT=ERROR"
  exit 2
}

[ -x "$SOLVE" ]  || error "$SOLVE not found/executable (build: gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz)"
[ -x "$VERIFY" ] || error "$VERIFY not found/executable (build: gcc -O2 -Wall -Wextra -o verify verify.c -lz -lpthread -lm)"
if [ "${Q908_ALLOW_STALE-}" != "1" ]; then
  . "$HERE/lib_binary_currency.sh"
  solve_binary_currency "$SOLVE" "$HERE/../solve.c" || error "$BINCUR_MSG (set Q908_ALLOW_STALE=1 to override, deliberately)"
  if [ "$VERIFY" -ot "$HERE/../verify.c" ]; then
    error "$VERIFY is older than verify.c — rebuild it (set Q908_ALLOW_STALE=1 to override, deliberately)"
  fi
fi
# capability probe: a verify without the mode would treat --c67-join as a run.out path
"$VERIFY" --c67-join > "$WORK/probe.out" 2>&1
grep -qx 'C67_JOIN_REFUSED=usage' "$WORK/probe.out" || error "$VERIFY has no --c67-join mode (stale build?)"

spec_for() {
  case "$1" in
    9)  echo "3.0,3.1,3.2@0" ;;
    10) echo "3.0,3.1,4.0@0" ;;
    *)  echo "" ;;
  esac
}

# args: FLAG S P1 P2 ... -> one "FLAG\nS:P1\nFLAG\nS+1:P2..." list
mkpins() {
  local flag="$1" s="$2"; shift 2
  local p
  for p in "$@"; do printf '%s\n%s\n' "$flag" "$s:$p"; s=$((s + 1)); done
}

# ie count for S P...; echoes the decimal or nothing
ie_count() {
  local s="$1"; shift
  local -a a; mapfile -t a < <(mkpins --ie-pin "$s" "$@")
  "$VERIFY" --ie-count --ie-spec "$SPEC" --ie-b0 "$B0" --ie-no-quotient "${a[@]}" \
    > "$WORK/ie.out" 2>&1
  awk '$1=="CRT" && $3=="N" && $4=="=" {print $5}' "$WORK/ie.out"
}
ie_brute() {
  local s="$1"; shift
  local -a a; mapfile -t a < <(mkpins --ie-pin "$s" "$@")
  "$VERIFY" --ie-count --ie-spec "$SPEC" --ie-b0 "$B0" --ie-no-quotient --ie-brute "${a[@]}" \
    > "$WORK/brute.out" 2>&1
  awk '$1=="BRUTE" && $3=="N" && $4=="=" {print $5}' "$WORK/brute.out"
}
# join on ladders FD GD for S P...; extra args after "--"; sets JRC, JOUT, JCOUNT
join_run() {
  local fd="$1" gd="$2" s="$3"; shift 3
  local -a pins=() extra=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do pins+=("$1"); shift; done
  [ $# -gt 0 ] && shift
  extra=("$@")
  local -a a; mapfile -t a < <(mkpins --join-pin "$s" "${pins[@]}")
  JOUT="$WORK/join.out"
  "$VERIFY" --c67-join "$fd" "$gd" "${a[@]}" "${extra[@]}" > "$JOUT" 2>&1
  JRC=$?
  JCOUNT=$(sed -n 's/^C67_JOIN_COUNT=\([0-9][0-9]*\)$/\1/p' "$JOUT")
}

# the full three-way check for one window; sets WCOUNT (the agreed count, or "")
check_window() {
  local name="$1" s="$2"; shift 2
  WCOUNT=""
  local ie br
  ie=$(ie_count "$s" "$@")
  br=$(ie_brute "$s" "$@")
  if [ -z "$ie" ] || [ -z "$br" ]; then
    bad "n=$N $name slots $s.. pins [$*]: ie/brute produced no count (see $WORK/ie.out, $WORK/brute.out)"
    return
  fi
  if [ "$ie" != "$br" ]; then
    bad "n=$N $name: ie $ie != brute $br"
    return
  fi
  join_run "$F" "$G" "$s" "$@" -- --join-expect "$ie"
  if [ "$JRC" -eq 0 ] && grep -qx 'C67_JOIN=PASS' "$JOUT" && [ "$JCOUNT" = "$ie" ] \
     && { grep -qx 'C67_JOIN_ORBIT_TILING=PASS' "$JOUT" || grep -qx 'C67_JOIN_NOTE=duplicate_pin_count_is_zero_by_definition' "$JOUT"; }; then
    ok "n=$N $name slots $s..$((s + $# - 1)) pins [$*]: join = ie = brute = $ie"
    echo "Q908_N${N}_${name}=MATCH:$ie"
    WCOUNT="$ie"
  else
    bad "n=$N $name slots $s.. pins [$*]: join rc=$JRC count='${JCOUNT}' vs ie=brute=$ie"
    sed 's/^/        | /' "$JOUT" | tail -n 25
  fi
}

# edit g layer values (v1 only): MODE ne|double|inc IDX
gedit() {
  python3 - "$1" "$2" "${3:-0}" <<'PYEOF'
import sys
p, mode, idx = sys.argv[1], sys.argv[2], int(sys.argv[3])
b = bytearray(open(p, 'rb').read())
if b[:8] != b'F1C5GLY1':
    print("NOT_V1"); sys.exit(3)
nm = int.from_bytes(b[32:40], 'little'); ne = int.from_bytes(b[40:48], 'little')
base = 72 + 4 * nm + 8 * (nm + 1) + 4 * ne
if len(b) != base + 24 * ne:
    print("BAD_SIZE"); sys.exit(3)
if mode == 'ne':
    print(ne); sys.exit(0)
def get(i): return int.from_bytes(b[base + 24 * i: base + 24 * i + 24], 'little')
def put(i, v): b[base + 24 * i: base + 24 * i + 24] = v.to_bytes(24, 'little')
if mode == 'double':
    for i in range(ne): put(i, 2 * get(i))
elif mode == 'inc':
    put(idx, get(idx) + 1)
else:
    print("BAD_MODE"); sys.exit(3)
open(p, 'wb').write(bytes(b))
PYEOF
}

first=1
for N in $NS; do
  SPEC=$(spec_for "$N")
  [ -n "$SPEC" ] || error "no ie spec mapped for n=$N (supported here: 9 10)"
  F="$WORK/f$N"; G="$WORK/g$N"
  rm -rf "$F" "$G"
  echo "== n=$N: build f and g ladders (solve --kc-build / --kc-g-build --f1-pairs $N) =="
  "$SOLVE" --kc-build "$F" --f1-pairs "$N" > "$WORK/build_f$N.log" 2>&1 || error "--kc-build n=$N failed (see $WORK/build_f$N.log)"
  "$SOLVE" --kc-g-build "$G" --f1-pairs "$N" > "$WORK/build_g$N.log" 2>&1 || error "--kc-g-build n=$N failed (see $WORK/build_g$N.log)"
  PL=$(sed -n 's/^pl=//p' "$F/f1c5_manifest.txt")
  B0=$(sed -n 's/^b0=//p' "$F/f1c5_manifest.txt")
  [ -n "$PL" ] && [ -n "$B0" ] || error "n=$N: f manifest lacks pl=/b0="
  mapfile -t Q < <(printf '%s\n' "$PL" | tr ',' '\n' | sort -n)
  [ "${#Q[@]}" -eq "$N" ] || error "n=$N: manifest pl has ${#Q[@]} entries"
  echo "   pl=$PL  b0=$B0  sorted=${Q[*]}"

  # the ie instance must be the same pair SET as the ladder's
  ie_count 1 "${Q[0]}" > /dev/null
  IEPL=$(sed -n 's/^instance: .*pairs=\([0-9,]*\)$/\1/p' "$WORK/ie.out" | tr ',' '\n' | sort -n | paste -sd, -)
  LDPL=$(printf '%s\n' "${Q[@]}" | paste -sd, -)
  if [ "$IEPL" = "$LDPL" ]; then ok "n=$N ie spec $SPEC names the ladder's pair set {$LDPL}"
  else bad "n=$N ie spec $SPEC pair set {$IEPL} != ladder pl {$LDPL}"; continue; fi

  nz=0; NZ_S=""; NZ_P=(); NZ_C=""
  run4() {   # name S p1 p2 p3 p4
    local name="$1" s="$2"; shift 2
    check_window "$name" "$s" "$@"
    # A planned window that happens to be empty proves little (0 = 0 = 0). Keep it (it was checked
    # three ways), then search its LAST pin over the instance's other pairs for a nonzero window of
    # the same shape; every candidate tried is itself checked three ways (join = ie = brute).
    if [ "$WCOUNT" = "0" ]; then
      local -a head=("${@:1:$(($# - 1))}") ; local P x used
      for P in "${Q[@]}"; do
        used=0; for x in "${head[@]}" "${!#}"; do [ "$x" = "$P" ] && used=1; done
        [ "$used" = 1 ] && continue
        check_window "${name}_SEARCH_P$P" "$s" "${head[@]}" "$P"
        if [ -n "$WCOUNT" ] && [ "$WCOUNT" != "0" ]; then set -- "${head[@]}" "$P"; break; fi
      done
    fi
    if [ -n "$WCOUNT" ] && [ "$WCOUNT" != "0" ]; then
      nz=$((nz + 1))
      if [ -z "$NZ_S" ]; then NZ_S="$s"; NZ_P=("$@"); NZ_C="$WCOUNT"; fi
    fi
  }
  run4 W1_C67_EQUIV $((N - 7)) "${Q[N-8]}" "${Q[N-7]}" "${Q[N-6]}" "${Q[N-5]}"
  run4 W2_START     1          "${Q[0]}" "${Q[1]}" "${Q[2]}" "${Q[3]}"
  run4 W3_END       $((N - 3)) "${Q[N-1]}" "${Q[N-3]}" "${Q[1]}" "${Q[N-2]}"
  run4 W4           3          "${Q[5]}" "${Q[0]}" "${Q[7]}" "${Q[2]}"
  run4 W5           2          "${Q[8]}" "${Q[4]}" "${Q[6]}" "${Q[3]}"
  run4 W6           4          "${Q[1]}" "${Q[6]}" "${Q[3]}" "${Q[8]}"
  if [ "$nz" -ge 2 ]; then ok "n=$N $nz of 6 four-slot windows are nonzero (agreement is not vacuous)"
  else bad "n=$N only $nz of 6 four-slot windows are nonzero — the agreement is vacuous"; fi

  # T3 + pin-sum identity
  check_window T3 2 "${Q[0]}" "${Q[1]}" "${Q[2]}"
  T3="$WCOUNT"
  if [ -n "$T3" ]; then
    sum=0; allok=1
    for ((i = 3; i < N; i++)); do
      check_window "PINSUM_P${Q[i]}" 2 "${Q[0]}" "${Q[1]}" "${Q[2]}" "${Q[i]}"
      if [ -z "$WCOUNT" ]; then allok=0; else sum=$((sum + WCOUNT)); fi
    done
    if [ "$allok" = 1 ] && [ "$sum" = "$T3" ]; then ok "n=$N pin-sum: sum over P of join(slot 5 := P) = $sum = join(3 pins)"
    else bad "n=$N pin-sum: sum $sum (all ran: $allok) != 3-pin $T3"; fi
  fi

  # duplicate pin
  check_window DUP 2 "${Q[0]}" "${Q[1]}" "${Q[0]}" "${Q[2]}"
  if [ "$WCOUNT" = "0" ] && grep -qx 'C67_JOIN_NOTE=duplicate_pin_count_is_zero_by_definition' "$JOUT"; then
    ok "n=$N duplicate pin: join 0 = ie 0"
  else bad "n=$N duplicate pin: expected 0 on both sides, got '$WCOUNT'"; fi

  # --join-c6c7 below full 31 must refuse
  "$VERIFY" --c67-join "$F" "$G" --join-c6c7 > "$WORK/c67.out" 2>&1; rc=$?
  if [ "$rc" -eq 2 ] && grep -qx 'C67_JOIN_REFUSED=c6c7_needs_full31' "$WORK/c67.out"; then ok "n=$N --join-c6c7 refused (needs full 31)"
  else bad "n=$N --join-c6c7 at n=$N: rc=$rc (want 2 + C67_JOIN_REFUSED=c6c7_needs_full31)"; fi

  if [ "$first" = 1 ] && [ -n "$NZ_S" ]; then
    first=0
    S="$NZ_S"; C="$NZ_C"; B=$((S + ${#NZ_P[@]} - 1))
    GL=$(printf 'g_layer_%02d.bin' "$B"); FL=$(printf 'f1c5_layer_%02d.bin' $((S - 1)))
    echo "== n=$N negative controls on window slots $S..$B pins [${NZ_P[*]}] (count $C; g layer $B) =="

    # doubled g layer
    GX="$WORK/g${N}_x2"; rm -rf "$GX"; cp -a "$G" "$GX"
    if [ "$(gedit "$GX/$GL" double)" = "" ]; then
      join_run "$F" "$GX" "$S" "${NZ_P[@]}" -- --join-expect "$C"
      want=$((2 * C))
      if [ "$JRC" -eq 1 ] && grep -qx 'C67_JOIN=FAIL' "$JOUT" && [ "$JCOUNT" = "$want" ]; then
        ok "NEG doubled g layer $B: count $JCOUNT = 2 x $C exactly; --join-expect $C -> C67_JOIN=FAIL rc 1"
      else bad "NEG doubled g layer: rc=$JRC count='$JCOUNT' (want rc 1, FAIL, $want)"; fi
    else bad "NEG doubled g layer: $GL is not an editable v1 layer"; fi

    # one g entry +1: some entry must move the count
    GS="$WORK/g${N}_one"; rm -rf "$GS"; cp -a "$G" "$GS"
    NE=$(gedit "$GS/$GL" ne)
    moved=""
    if [ -n "$NE" ] && [ "$NE" -gt 0 ] 2>/dev/null; then
      lim=$NE; [ "$lim" -gt 4096 ] && lim=4096
      for ((j = 0; j < lim; j++)); do
        cp "$G/$GL" "$GS/$GL"
        gedit "$GS/$GL" inc "$j" > /dev/null || break
        join_run "$F" "$GS" "$S" "${NZ_P[@]}" -- --join-expect "$C"
        if [ "$JRC" -eq 1 ] && grep -qx 'C67_JOIN=FAIL' "$JOUT" && [ -n "$JCOUNT" ] && [ "$JCOUNT" != "$C" ]; then
          moved="$j"; break
        fi
      done
    fi
    if [ -n "$moved" ]; then ok "NEG single g entry #$moved of layer $B +1: count $C -> $JCOUNT, C67_JOIN=FAIL rc 1"
    else bad "NEG single g entry: no single +1 corruption among the first entries moved the count"; fi

    # wrong pin: replace the last pin by another pair whose ie count differs
    wrong=""
    for P in "${Q[@]}"; do
      skip=0; for x in "${NZ_P[@]}"; do [ "$x" = "$P" ] && skip=1; done
      [ "$skip" = 1 ] && continue
      WP=("${NZ_P[@]:0:${#NZ_P[@]}-1}" "$P")
      iw=$(ie_count "$S" "${WP[@]}")
      [ -n "$iw" ] && [ "$iw" != "$C" ] || continue
      join_run "$F" "$G" "$S" "${WP[@]}" -- --join-expect "$C"
      if [ "$JRC" -eq 1 ] && grep -qx 'C67_JOIN=FAIL' "$JOUT" && [ "$JCOUNT" = "$iw" ]; then
        wrong="$P:$iw"
      else wrong="BAD"; fi
      break
    done
    case "$wrong" in
      "")  bad "NEG wrong pin: no replacement pair with a different ie count was found" ;;
      BAD) bad "NEG wrong pin: join rc=$JRC count='$JCOUNT' (want rc 1, FAIL, the wrong pins' ie count)" ;;
      *)   ok "NEG wrong pin (last pin := ${wrong%%:*}): join = ie = ${wrong#*:} != $C -> C67_JOIN=FAIL rc 1" ;;
    esac

    # truncated g layer
    GT="$WORK/g${N}_trunc"; rm -rf "$GT"; cp -a "$G" "$GT"
    truncate -s -1 "$GT/$GL"
    join_run "$F" "$GT" "$S" "${NZ_P[@]}" -- --join-expect "$C"
    if [ "$JRC" -eq 2 ] && grep -qx 'C67_JOIN=REFUSED' "$JOUT" && grep -qx 'C67_JOIN_REFUSED=g_layer_open_or_header' "$JOUT" && [ -z "$JCOUNT" ]; then
      ok "NEG truncated g layer $B: C67_JOIN=REFUSED (g_layer_open_or_header) rc 2, no count"
    else bad "NEG truncated g layer: rc=$JRC count='$JCOUNT'"; fi

    # missing f layer
    FM="$WORK/f${N}_missing"; rm -rf "$FM"; cp -a "$F" "$FM"; rm -f "$FM/$FL"
    join_run "$FM" "$G" "$S" "${NZ_P[@]}" -- --join-expect "$C"
    if [ "$JRC" -eq 2 ] && grep -qx 'C67_JOIN_REFUSED=f_layer_open_or_header' "$JOUT" && [ -z "$JCOUNT" ]; then
      ok "NEG missing f layer $((S - 1)): C67_JOIN=REFUSED (f_layer_open_or_header) rc 2"
    else bad "NEG missing f layer: rc=$JRC count='$JCOUNT'"; fi

    # pair not in the instance
    outp=""
    for ((P = 1; P <= 31; P++)); do
      inq=0; for x in "${Q[@]}"; do [ "$x" = "$P" ] && inq=1; done
      [ "$inq" = 0 ] && { outp="$P"; break; }
    done
    join_run "$F" "$G" "$S" "${NZ_P[@]:0:${#NZ_P[@]}-1}" "$outp"
    if [ "$JRC" -eq 2 ] && grep -qx 'C67_JOIN_REFUSED=pin_pair_not_in_instance' "$JOUT"; then
      ok "NEG pair $outp (not in the instance): refused"
    else bad "NEG pair not in instance: rc=$JRC"; fi

    # non-consecutive slots
    "$VERIFY" --c67-join "$F" "$G" --join-pin "2:${Q[0]}" --join-pin "4:${Q[1]}" > "$WORK/gap.out" 2>&1; rc=$?
    if [ "$rc" -eq 2 ] && grep -qx 'C67_JOIN_REFUSED=slots_not_consecutive' "$WORK/gap.out"; then
      ok "NEG slots 2,4 (gap): refused"
    else bad "NEG slots with a gap: rc=$rc"; fi
  fi
done
[ "$first" = 0 ] || bad "negative controls never ran (no nonzero window on the first n)"

echo "Q908_JOIN_CHECKS=$checks"
echo "Q908_JOIN_FAILS=$fails"
if [ "$fails" -eq 0 ] && [ "$checks" -gt 0 ]; then
  echo "Q908_JOIN_ACCEPT=PASS"
  exit 0
fi
echo "Q908_JOIN_ACCEPT=FAIL"
exit 1
