#!/usr/bin/env bash
# f1c5_adopt_digest_gate.sh — the finalized-layer ADOPT path must compare the digest it prints.
#
# WHY. Until 2026-09-10 f1c5_finalized_try_adopt() read the .finalized marker's
# sha256_decompressed, PRINTED it in the "adopted finalized layer" line, and never compared it —
# documented as intended. RCQ03 finding 2 measured what that costs: flip byte 100 of an n=9 f
# layer 1 (the low byte of off[2], inside the offset table), resume, and the build ADOPTS the
# altered layer, logs the ORIGINAL digest for a file that no longer has it, and exits 0 with
#   orbit-quotient C5-DP total = 18768        (a clean build is 26112)
# No token said anything was wrong. The structural checks cannot see it — a bumped offset is
# still monotone with the right endpoints — and a follow-up detection test (F2_GCHECK_DETECTS=NO)
# showed --kc-g-check PASSES on a large fraction of instances of the same class, and
# --kc-ladder-verify PASSES too when the eviction lands in the sidecar window (the resume
# regenerates the sidecar from the altered bytes). The marker's own digest is the check.
#
# WHAT IS GATED. Five legs, and the two DIRECTIONS matter equally: a gate that only proves the
# refusal would pass on a binary that refuses everything, which would make every eviction-resume
# a full re-sweep — worse than the defect.
#   A  corrupt layer, gate on   -> refuses (F1C5_ADOPT_DIGEST=MISMATCH), re-sweeps, total 26112
#   B  clean layer,   gate on   -> ADOPTS  (F1C5_ADOPT_DIGEST=OK),                  total 26112
#   C  marker with no digest    -> refuses (F1C5_ADOPT_DIGEST=MISSING), re-sweeps,  total 26112
#   D  C + SOLVE_F1_ADOPT_UNVERIFIED=1 -> adopts unattested (=UNVERIFIED),          total 26112
#   E  corrupt + SOLVE_F1_ADOPT_UNVERIFIED=1 -> STILL refuses (=MISMATCH). The opt-out covers a
#      marker that cannot be checked, never one that can be and fails. E is the mutant leg: the
#      first draft of this fix read the env var before recomputing, and E measured 18768 with the
#      env set — the same defect, one variable away.
#
# Leg B is the mutation control in the other direction: revert the comparison and B still passes
# while A fails, so A alone is the red test and B alone is the availability test; both are needed.
#
# Usage: scripts/f1c5_adopt_digest_gate.sh [path-to-solve-binary]      (default ./solve)
# Verdict: exactly one whole line, consume with grep -qx.
#   F1C5_ADOPT_DIGEST_GATE=PASS   all five legs held.                              rc 0
#   F1C5_ADOPT_DIGEST_GATE=FAIL   at least one leg did not.                        rc 1
#   F1C5_ADOPT_DIGEST_GATE=ERROR  the gate could not MEASURE (no binary, no drill
#                                 hook, no marker) — never read as agreement.      rc 40
#
# Developed with AI assistance (Claude, Anthropic). Reviewer of the underlying finding: Codex
# (gpt-6-astra), acknowledged as a reviewer.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "F1C5_ADOPT_DIGEST_GATE=ERROR"; exit 40; }
SOLVE="${1:-./solve}"
[ -x "$SOLVE" ] || { echo "  [ERROR] no executable at $SOLVE — build first"; echo "F1C5_ADOPT_DIGEST_GATE=ERROR"; exit 40; }
SOLVE="$(cd "$(dirname "$SOLVE")" && pwd)/$(basename "$SOLVE")"

# 🔴 A STALE BINARY MUST NOT READ AS A BROKEN FIX. Added 2026-09-10, minutes after this gate misled
# its own author. Run bare, it defaults to ./solve -- the CHECKED-IN binary, which in this
# repository is routinely stale (measured today: 131 h behind solve.c). Against that artifact the
# gate reported, correctly and uselessly:
#     [FAIL] A: total=18768, expected 26112       F1C5_ADOPT_DIGEST_GATE=FAIL
# i.e. the exact defect signature -- for a binary that simply predates the fix. The gate was right
# about the artifact it was handed and silent about the only thing that made the answer meaningless.
# A reader less suspicious than they should be concludes the fix is broken and reverts it.
# So: compare the binary's embedded SOURCE_SHA against sha256(solve.c) and ERROR -- never FAIL --
# when they differ. "I was given the wrong binary" is not "the code is wrong", and this project
# treats an unmeasured check as ERROR precisely so the two cannot be confused.
W_PRE="$(mktemp -u "${TMPDIR:-/tmp}/f1c5_pre_XXXXXX")"
_src_sha=$(sha256sum solve.c 2>/dev/null | cut -d' ' -f1)
if [ -n "${_src_sha:-}" ]; then
  # 🔴 MATERIALISE, THEN GREP. `strings … | grep -qF` under `set -o pipefail` INVERTS THIS CHECK:
  # grep -q exits at the first match and SIGPIPEs strings, so the pipeline reports failure exactly
  # when the sha IS present. Written that way first, and it made a correctly-built binary ERROR --
  # the guard against a misleading verdict producing a misleading verdict.
  # [[feedback_pipefail_which_side_ends_first]] names this trap precisely.
  _bs="$W_PRE.strings"; strings -a "$SOLVE" > "$_bs" 2>/dev/null || true
  if ! grep -qF -- "$_src_sha" "$_bs"; then
    rm -f "$_bs"
    echo "  [ERROR] $SOLVE does not embed sha256(solve.c)=${_src_sha:0:12}… — it was built from"
    echo "          DIFFERENT SOURCE. Every verdict below would describe that other source, and a"
    echo "          stale binary reproduces this gate's own failure signature exactly."
    echo "          Build first, then pass the path:"
    echo "            gcc -O2 -pthread -fopenmp -DSOURCE_SHA=\"\$(sha256sum solve.c | cut -d' ' -f1)\" \\"
    echo "                -o /tmp/solve solve.c -lm -lz && $0 /tmp/solve"
    echo "F1C5_ADOPT_DIGEST_GATE=ERROR"; exit 40
  fi
  rm -f "$_bs"
fi

W="$(mktemp -d "${TMPDIR:-/tmp}/f1c5_adopt_gate_XXXXXX")" || { echo "F1C5_ADOPT_DIGEST_GATE=ERROR"; exit 40; }
trap 'rm -rf "$W"' EXIT
CLEAN_TOTAL=26112          # n=9 --f1-exact-c1c2c4c5, TR-11 published
FLIP_OFF=100               # low byte of off[2] in the v2 layer-1 header (RCQ03 finding 2's byte)
fails=0

# --- build the interrupted state once: layer 1 finalized, manifest NOT advanced -----------
mk_seed() {  # $1 = dir, $2 = extra env ("" or SOLVE_F1_FINALIZE_SHA=0)
  env SOLVE_F1_KEEP_LAYERS=1 SOLVE_F1_KILL_BEFORE_MANIFEST=1 ${2:+$2} \
      "$SOLVE" --f1-exact-c1c2c4c5 --f1-pairs 9 --f1-out-of-core "$1" >/dev/null 2>&1
  [ -f "$1/f1c5_layer_01.finalized" ] && [ -f "$1/f1c5_layer_01.bin" ]
}
mk_seed "$W/seed" "" || { echo "  [ERROR] SOLVE_F1_KILL_BEFORE_MANIFEST produced no layer-1 marker"; echo "F1C5_ADOPT_DIGEST_GATE=ERROR"; exit 40; }
grep -q '^sha256_decompressed=[0-9a-f]\{64\}$' "$W/seed/f1c5_layer_01.finalized" || {
  echo "  [ERROR] the marker carries no digest — nothing to gate"; echo "F1C5_ADOPT_DIGEST_GATE=ERROR"; exit 40; }
mk_seed "$W/seed0" "SOLVE_F1_FINALIZE_SHA=0" || { echo "  [ERROR] no marker under SOLVE_F1_FINALIZE_SHA=0"; echo "F1C5_ADOPT_DIGEST_GATE=ERROR"; exit 40; }

leg() {  # $1 leg  $2 seed  $3 flip(y/n)  $4 env  $5 want_token  $6 want_adopt(y/n)
  local name="$1" d="$W/run_$1"
  rm -rf "$d"; cp -a "$2" "$d"
  [ "$3" = y ] && printf '\x03' | dd of="$d/f1c5_layer_01.bin" bs=1 seek=$FLIP_OFF conv=notrunc status=none
  env SOLVE_F1_KEEP_LAYERS=1 ${4:+$4} "$SOLVE" --f1-exact-c1c2c4c5 --f1-pairs 9 \
      --f1-out-of-core "$d" >"$d/out" 2>"$d/err"
  local rc=$? tot adopt=n ok=1
  tot="$(sed -n 's/.*orbit-quotient C5-DP total = \([0-9]*\).*/\1/p' "$d/out" | tail -1)"
  grep -q 'adopted finalized layer' "$d/err" && adopt=y
  grep -qx "F1C5_ADOPT_DIGEST=$5" "$d/err" || { echo "  [FAIL] $name: expected whole line F1C5_ADOPT_DIGEST=$5; got: $(grep '^F1C5_ADOPT_DIGEST' "$d/err" | tr '\n' ' ')"; ok=0; }
  [ "$adopt" = "$6" ] || { echo "  [FAIL] $name: adopted=$adopt, expected $6"; ok=0; }
  [ "${tot:-none}" = "$CLEAN_TOTAL" ] || { echo "  [FAIL] $name: total=${tot:-none}, expected $CLEAN_TOTAL"; ok=0; }
  [ "$rc" = 0 ] || { echo "  [FAIL] $name: rc=$rc, expected 0 (a refused ADOPTION must not fail the BUILD)"; ok=0; }
  [ "$ok" = 1 ] && echo "  [ok] $name: token=$5 adopted=$adopt total=$tot rc=$rc" || fails=$((fails+1))
}

echo "== the byte-flip must be refused, and a clean resume must still adopt =="
leg A "$W/seed"  y ""                            MISMATCH   n
leg B "$W/seed"  n ""                            OK         y
leg C "$W/seed0" n ""                            MISSING    n
leg D "$W/seed0" n "SOLVE_F1_ADOPT_UNVERIFIED=1" UNVERIFIED y
leg E "$W/seed"  y "SOLVE_F1_ADOPT_UNVERIFIED=1" MISMATCH   n

if [ "$fails" = 0 ]; then echo "F1C5_ADOPT_DIGEST_GATE=PASS"; exit 0; fi
echo "F1C5_ADOPT_DIGEST_GATE=FAIL"; exit 1
