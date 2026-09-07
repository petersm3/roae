#!/usr/bin/env bash
# MANIFEST_ZERO_ENTRY=PASS|FAIL|ERROR
#
# Q-445 (ledger rule ST-481). A fresh `solve` run BRICKED its own run directory.
#
#   canonical-enum startup order:
#     auto_verify_shard_manifest_if_exists()   -> non-zero means exit 22
#     ...
#     auto_emit_shard_manifest_default()       -> ~238 ms after launch
#
#   do_emit_shard_manifest() used to run `find sub_*.bin | ... | sort > tmp && mv tmp manifest`.
#   With NO shards on disk the pipeline still succeeded, so a ZERO-BYTE shard_manifest.txt was
#   installed -- its own log says "wrote 0 entries". The NEXT launch found that manifest and the
#   Q-367 guard in do_verify_shard_manifest() (total == 0 -> 22) correctly refused to report PASS
#   on a manifest with nothing in it. Fresh run, relaunch, exit 22 -- deterministic, 7/7.
#
#   The window opens at ~238 ms and lasts the WHOLE run: the manifest is refreshed only at startup
#   or on CLEAN completion, so finished shards do not close it. SIGTERM/SIGINT self-heal (they
#   drain, flush and re-emit a good manifest), so the exposure is SIGKILL-class only -- hard
#   eviction, OOM-kill, host crash, kill -9 -- a class that does occur here (rc=137 is treated as
#   eviction-class). Below 1T `dfs_checkpoint_enabled` is 0, so no `.dfs_state` is ever written and
#   the #164 resume downgrade never arms. `rm shard_manifest.txt` unblocks but is NOT sticky: the
#   next launch re-writes a zero-entry manifest at 238 ms and re-arms the trap.
#
# THE FIX IS AT THE WRITE SITE, AND LEG 2a IS WHY. The tempting fix is to let the verifier tolerate
# an empty manifest "on a fresh directory". At verify time a fresh directory is INDISTINGUISHABLE
# from a truncated sidecar write, so that tolerance would hand PASS to the state most likely to
# mean the manifest is broken -- the verifier-closure invariant (Codex N07): a verifier must be
# able to be FALSE when its target is absent. A manifest attests "these N shards had these hashes";
# with zero shards there is nothing to attest, so the right artifact is NO manifest. The emitter
# owns it:            shard_manifest.txt exists  ==>  it attests >= 1 shard.
#
# THREE LEGS, and mutant M2 is the reason there are three:
#   L1   fresh run -> SIGKILL -> relaunch must NOT exit 22       (kills M1, the un-fixed emitter)
#   L2A  a hand-planted ZERO-ENTRY manifest must STILL exit 22   (kills M2, the tolerant verifier)
#   L2B  a non-empty but WRONG manifest must STILL exit 22       (Q-367 unweakened -- the charge)
# M2 -- revert the emitter guard AND make `total == 0` return 0 -- clears L1 and is exactly the
# regression Q-367 closed. Only L2A sees it. A gate whose legs all fall to the same fault has one
# leg, not three.
#
# On the UNFIXED source this gate reports FAIL (not ERROR): the baseline legs run first and
# L1=BRICKED exits FAIL before any mutant is built.

set -uo pipefail
cd "$(dirname "$0")/.." || { echo "MANIFEST_ZERO_ENTRY=ERROR cannot reach repo root"; exit 2; }
WORK=$(mktemp -d) || { echo "MANIFEST_ZERO_ENTRY=ERROR mktemp failed"; exit 2; }
trap '[ -n "${WORK:-}" ] && rm -rf "$WORK"' EXIT
fail(){ echo "  [ERROR] $*"; echo "MANIFEST_ZERO_ENTRY=ERROR"; exit 2; }

[ -f solve.c ] || fail "missing solve.c"
command -v gcc     >/dev/null 2>&1 || fail "no gcc"
command -v python3 >/dev/null 2>&1 || fail "no python3"
BUILD=$(grep -m1 -E '^gcc .*solve\.c' documentation/VERIFY.md 2>/dev/null)
[ -n "$BUILD" ] || fail "no published 'gcc ... solve.c' build line in documentation/VERIFY.md"

# --- build -------------------------------------------------------------------------------
# Compile the source AS solve.c in its OWN directory. Do NOT rewrite the filename inside the
# published build line: that line reads
#     -DSOURCE_SHA="\"$(sha256sum solve.c | cut -d' ' -f1)\"" -o solve solve.c
# so a `${BUILD/solve.c/$src}` substitution hits the sha256sum ARGUMENT first and leaves the
# compiled input as the pristine solve.c -- every mutant would silently be the FIXED source and be
# reported SURVIVED. Only `-o solve` is rewritten, and build_verified then PROVES what was built by
# finding that source's own sha (baked in by -DSOURCE_SHA) inside the binary image.
build_verified(){ # build_verified <src> <tag> -> $WORK/b_<tag>/bin
  local src="$1" tag="$2" d want
  d="$WORK/b_$tag"
  rm -rf "$d"; mkdir -p "$d" || return 2
  cp "$src" "$d/solve.c" || return 2
  ( cd "$d" && eval "nice -n 10 ${BUILD/-o solve/-o $d/bin}" ) >"$WORK/build_$tag.log" 2>&1
  [ -x "$d/bin" ] || { echo "  [ERROR] $tag: compile produced no binary (see $WORK/build_$tag.log)"; return 2; }
  want=$(sha256sum "$src" | cut -d' ' -f1)
  # Not a pipeline: grep's own status IS the answer, so there is no producer to SIGPIPE.
  grep -a -F -q -e "$want" "$d/bin" || {
    echo "  [ERROR] $tag: binary does not carry SOURCE_SHA=$want -- it compiled a DIFFERENT file"
    return 2; }
  return 0
}

# --- probe runs --------------------------------------------------------------------------
# 999B < 1T, so the disk-space / IOPS / auto-selftest pre-gates all skip themselves and the probe
# stays cheap. The per-sub-branch budget lands at ~330M nodes, far more than the run can finish, so
# run 1 CANNOT complete -- and a clean completion would re-emit a valid manifest and hide the bug.
# SOLVE_SKIP_AUTO_MANIFEST is deliberately NOT set: that switch disables the mechanism under test.
run_bg(){ # run_bg <dir> <bin> <log> ; sets RB_PID to the solve pid
  ( cd "$1" && exec env -u SOLVE_DEPTH -u SOLVE_PER_SUB_BRANCH_LIMIT -u SOLVE_SKIP_AUTO_MANIFEST \
      SOLVE_THREADS=2 SOLVE_NODE_LIMIT=999000000000 \
      SOLVE_ALLOW_SUB_CANONICAL=1 SOLVE_SKIP_CANONICAL_LOCK=1 \
      SOLVE_SKIP_AUTO_SELFTEST=1 SOLVE_SKIP_DISK_CHECK=1 \
      SOLVE_SKIP_IOPS_CHECK=1 SOLVE_SKIP_BINARY_SNAPSHOT=1 \
      "$2" 0 ) >"$1/$3" 2>&1 &
  RB_PID=$!
}

# MEASURED marker order in a real run log (2026-09-07):
#   [hardening] no prior shard_manifest.txt; first-run or fresh dir (auto-verify SKIPPED, ...)
#   [hardening] auto-emit-manifest: snapshotting shard state to shard_manifest.txt   <- GATE_CLEARED
#   [hardening] auto-emit-manifest: wrote 0 entries                                  <- EMIT_SETTLED
#   Starting enumeration...
GATE_CLEARED='auto-emit-manifest: snapshotting'
EMIT_SETTLED='auto-emit-manifest: wrote|no manifest emitted|auto-emit-manifest failed'

# A fixed wall-clock timeout is NOT a measurement on a contended box: "still running at N seconds"
# cannot be told apart from "has not reached the gate yet", and reading the second as "the gate
# passed" would hand a mutant a free PASS. So we wait for a POSITIVE marker, and anything else is
# NOMEASURE, which every caller turns into ERROR -- never PASS, never FAIL.
#
# These set the global PROBE_V instead of echoing. They must NOT run inside $( ): the background
# job belongs to THIS shell, and `wait` from a subshell is not the job's parent -- it returns 127,
# which would be read as "not 22" and silently invert every REFUSED verdict.
WINDOW_S=${MANIFEST_ZERO_ENTRY_WINDOW_S:-240}
await(){ # await <pid> <log> <marker-ere> -> PROBE_V = REFUSED | MARKED | NOMEASURE(...)
  local pid="$1" log="$2" marker="$3" n=$(( WINDOW_S * 4 )) i=0 rc
  while [ "$i" -lt "$n" ]; do
    if [ -f "$log" ] && grep -a -E -q -e "$marker" "$log"; then PROBE_V=MARKED; return 0; fi
    if ! kill -0 "$pid" 2>/dev/null; then
      wait "$pid"; rc=$?
      if [ -f "$log" ] && grep -a -E -q -e "$marker" "$log"; then PROBE_V=MARKED; return 0; fi
      if [ "$rc" = 22 ]; then PROBE_V=REFUSED; else PROBE_V="NOMEASURE(rc=$rc)"; fi
      return 0
    fi
    sleep 0.25   # a real sleep: `until cmd; do :; done` forks ~370/s and pegs a 2-core box
    i=$(( i + 1 ))
  done
  PROBE_V='NOMEASURE(timeout)'
  return 0
}
hardkill(){ kill -9 "$1" 2>/dev/null; wait "$1" 2>/dev/null; return 0; }

WRONG_LINE=$(printf 'sub_99_0_98_1.bin\t4096\t%s' \
  '0000000000000000000000000000000000000000000000000000000000000000')

legs(){ # legs <bin> <tag> -> one token per line: L1=.. L2A=.. L2B=..
  local S="$1" tag="$2" d

  # --- L1: fresh dir -> run -> SIGKILL -> relaunch --------------------------------------
  # SIGKILL is the only signal class that reaches this defect; SIGTERM/SIGINT drain and re-emit a
  # good manifest. We wait for EMIT_SETTLED, not merely for the emitter to START, so the kill is
  # known to land AFTER the emitter finished -- killing mid-emit would be a race, not a test.
  d="$WORK/r_$tag"; rm -rf "$d"; mkdir -p "$d"
  run_bg "$d" "$S" r1.log
  await "$RB_PID" "$d/r1.log" "$EMIT_SETTLED"
  hardkill "$RB_PID"
  if [ "$PROBE_V" != MARKED ]; then
    echo "L1=NOMEASURE(run1=$PROBE_V)"; echo "L2A=NOMEASURE(skipped)"; echo "L2B=NOMEASURE(skipped)"
    return 0
  fi
  if [ -f "$d/shard_manifest.txt" ]; then
    echo "  [obs] $tag: run 1 left shard_manifest.txt with $(wc -l < "$d/shard_manifest.txt") entries" >&2
  else
    echo "  [obs] $tag: run 1 left NO shard_manifest.txt" >&2
  fi
  run_bg "$d" "$S" r2.log
  await "$RB_PID" "$d/r2.log" "$GATE_CLEARED"
  hardkill "$RB_PID"
  case "$PROBE_V" in
    REFUSED) echo "L1=BRICKED" ;;
    MARKED)  echo "L1=CLEAN" ;;
    *)       echo "L1=NOMEASURE($PROBE_V)" ;;
  esac

  # --- L2A: a hand-planted ZERO-ENTRY manifest must still be refused --------------------
  # The isolating leg. The fix must not weaken the verifier: on a fresh directory an empty
  # manifest is indistinguishable from a truncated sidecar write (Q-367 / Codex N07).
  d="$WORK/z_$tag"; rm -rf "$d"; mkdir -p "$d"; : > "$d/shard_manifest.txt"
  run_bg "$d" "$S" z.log
  await "$RB_PID" "$d/z.log" "$GATE_CLEARED"
  hardkill "$RB_PID"
  case "$PROBE_V" in
    REFUSED) echo "L2A=GUARD" ;;
    MARKED)  echo "L2A=BAD(empty manifest accepted)" ;;
    *)       echo "L2A=NOMEASURE($PROBE_V)" ;;
  esac

  # --- L2B: a non-empty but WRONG manifest must still be refused ------------------------
  d="$WORK/w_$tag"; rm -rf "$d"; mkdir -p "$d"; printf '%s\n' "$WRONG_LINE" > "$d/shard_manifest.txt"
  run_bg "$d" "$S" w.log
  await "$RB_PID" "$d/w.log" "$GATE_CLEARED"
  hardkill "$RB_PID"
  case "$PROBE_V" in
    REFUSED) echo "L2B=GUARD" ;;
    MARKED)  echo "L2B=BAD(wrong manifest accepted)" ;;
    *)       echo "L2B=NOMEASURE($PROBE_V)" ;;
  esac
}

count_legs(){ printf '%s\n' "$1" | grep -c -E '^L[0-9A-Z]+='; }   # grep -c reads to EOF: no SIGPIPE

# --- baseline: the committed source -------------------------------------------------------
if [ -n "${MANIFEST_ZERO_ENTRY_SOLVE:-}" ]; then
  SOLVE="$MANIFEST_ZERO_ENTRY_SOLVE"
  [ -x "$SOLVE" ] || fail "MANIFEST_ZERO_ENTRY_SOLVE=$SOLVE is not executable"
  echo "  [gate] baseline binary handed in: $SOLVE"
else
  build_verified solve.c base || fail "published build line failed on the committed solve.c"
  SOLVE="$WORK/b_base/bin"
fi
BASE=$(legs "$SOLVE" base)
# NEVER `legs ... | grep -q`: under pipefail grep -q exits at the first match and SIGPIPEs the
# producer, so the pipeline reports 141 and a match reads as NO match, inverting every verdict.
# Capture first, match the captured string second.
[ "$(count_legs "$BASE")" = 3 ] || fail "baseline produced $(count_legs "$BASE") leg verdicts, not 3 -- nothing was measured"
printf '%s\n' "$BASE" | sed 's/^/  [gate] baseline /'
case "$BASE" in *NOMEASURE*) fail "baseline: a leg measured nothing" ;; esac
case "$BASE" in *L1=BRICKED*|*=BAD*)
  echo "  [FAIL] baseline: the committed solve.c does not hold the invariant"
  echo "MANIFEST_ZERO_ENTRY=FAIL"; exit 1 ;;
esac
echo "  [gate] baseline holds all 3 legs"

# --- mutants ------------------------------------------------------------------------------
cat > "$WORK/m1.py" <<'PY'
# M1: restore the pre-fix emitter -- `sort > tmp && mv tmp manifest`, unconditionally.
import sys
s = open(sys.argv[1], encoding='utf-8').read()
a = s.index('''             "' _ | LC_ALL=C sort > %s",''')
b = s.index('\n    return 0;\n}\n', a) + len('\n    return 0;\n}\n')
open(sys.argv[2], 'w', encoding='utf-8').write(s[:a] + '''             "' _ | LC_ALL=C sort > %s.tmp && mv %s.tmp %s",
             threads, tool, tool, manifest_path, manifest_path, manifest_path);
    int rc = system(cmd);
    if (rc != 0) return 30;
    return 0;
}
''' + s[b:])
PY
cat > "$WORK/m2.py" <<'PY'
# M2: on top of M1, make the Q-367 zero-entry guard report PASS -- the "tolerant verifier" half-fix.
import sys
s = open(sys.argv[1], encoding='utf-8').read()
k = s.index("ERROR: shard manifest '%s' has ZERO entries.")
j = s.index('        return 22;\n', k)
open(sys.argv[2], 'w', encoding='utf-8').write(
    s[:j] + '        return 0;   /* MUTANT M2: tolerant verifier */\n'
          + s[j + len('        return 22;\n'):])
PY

mutate(){ # mutate <name> <script> <src-in> <killed-by-glob> -> 0 KILLED, 1 SURVIVED, 2 unmeasurable
  local name="$1" py="$2" src="$3" want="$4" out
  python3 "$py" "$src" "$WORK/m_$name.c" || { echo "  [ERROR] mutant $name: patch script failed (anchor drift?)"; return 2; }
  cmp -s "$src" "$WORK/m_$name.c" && { echo "  [ERROR] mutant $name did not change the source"; return 2; }
  build_verified "$WORK/m_$name.c" "$name" || return 2
  out=$(legs "$WORK/b_$name/bin" "$name")
  [ "$(count_legs "$out")" = 3 ] || { echo "  [ERROR] mutant $name produced $(count_legs "$out") leg verdicts, not 3"; return 2; }
  printf '%s\n' "$out" | sed "s/^/  [gate] mutant $name /"
  case "$out" in *NOMEASURE*) echo "  [ERROR] mutant $name: a leg measured nothing"; return 2 ;; esac
  case "$out" in $want) echo "  [gate] mutant $name killed"; return 0 ;; esac
  echo "  [FAIL] mutant $name SURVIVED -- the gate cannot see this fault"
  return 1
}

RC=0
mutate m1 "$WORK/m1.py" solve.c '*L1=BRICKED*'
case $? in 0) ;; 1) RC=1 ;; *) fail "mutant m1 could not be measured" ;; esac

python3 "$WORK/m1.py" solve.c "$WORK/seed_m2.c" || fail "m1 patch failed while seeding m2"
mutate m2 "$WORK/m2.py" "$WORK/seed_m2.c" '*L2A=BAD*'
case $? in 0) ;; 1) RC=1 ;; *) fail "mutant m2 could not be measured" ;; esac

if [ "$RC" = 0 ]; then echo "MANIFEST_ZERO_ENTRY=PASS"; exit 0; fi
echo "MANIFEST_ZERO_ENTRY=FAIL"; exit 1
