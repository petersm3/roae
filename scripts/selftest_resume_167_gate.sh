#!/usr/bin/env bash
# selftest_resume_167_gate.sh — a NON-VACUITY gate for the #167 zero-yield resume fix (Q-414).
#
# ============================================================================================
# WHY THIS EXISTS
# ============================================================================================
# `solve --selftest-resume` is the standing acceptance test for the resume path, and on the
# #167 zero-yield fix it is BLIND IN BOTH DIRECTIONS. Measured 2026-09-04: the fixed binary and
# the pre-fix baseline both PASS it, byte-identically, and the run reports nothing about the
# guard at all. Two independent reasons, both structural rather than incidental:
#
#   1. THE GUARD'S OUTPUT CANNOT REACH THE CALLER. The driver runs PHASE_A / PHASE_B /
#      single-shot as three system() children whose stderr is redirected into phase_?.log
#      INSIDE the two tempdirs, and then `rm -rf`s both directories before returning
#      (solve.c, the `rm -rf '%s' '%s'` immediately after the two shas are read). Every
#      `[#167-guard]` line is deleted before anyone can count it, on every binary, forever.
#
#   2. THE VERDICT IS INSENSITIVE TO THE DEFECT. Discard-and-re-walk of a zero-yield cell
#      produces exactly the single-shot solution set — that is the guard's own correctness
#      claim — so the sha comparison passes whether the cell resumed or re-walked. The fix
#      changes WORK, not OUTPUT, and the sha comparator measures only output.
#
# A green test that cannot see its target is this project's dominant failure class, and it was
# sitting inside the acceptance test for a resume-path fix. This script is the gate that can
# fail. It re-runs the same three-phase shape as `--selftest-resume` but keeps the artifacts,
# and it decides on FOUR quantities, three of which the guard does not produce:
#
#   Z  zero-yield cells      counted from the FILESYSTEM (sidecars with no shard) — so the
#                            gate does not learn its subject from the thing under test
#   R  guard resumed         counted from phase_b.log BEFORE anything is deleted
#   D  guard discarded       counted from phase_b.log BEFORE anything is deleted
#   EXCESS = nodes_A + nodes_B - nodes_single, summed from the per-run `checkpoint_t*.txt`
#                            lines, which the guard does not write. A second, independent
#                            witness that the resume actually SAVED the work it claims.
#
# The verifier holds no witness from its own closure (feedback_verifier_closure_invariant):
# a guard that is never reached (R=D=0) and a guard that silently discards (D=Z) both FAIL,
# and a run in which no zero-yield cell exists at all is reported VACUOUS, never PASS.
#
# 🔴 DO NOT use `prior_nodes_walked` from the sidecar as the work witness. It is cumulative and
# reads budget-1 whether the cell resumed or re-walked, so it cannot discriminate (Fable,
# Q414_FABLE_ATTACK_2026_09_04). EXCESS is per-RUN and does discriminate.
#
# ============================================================================================
# VERDICTS  (first rule that applies wins)
# ============================================================================================
#   Z == 0                        -> VACUOUS rc 42  no zero-yield sidecar exists; the #167 path
#                                                   cannot be exercised at this shape
#   R + D == 0                    -> VACUOUS rc 42  Z>0 shard-less sidecars and the guard
#                                                   reported on none of them
#   sha_resume != sha_single      -> FAIL    rc 40  (the existing --selftest-resume check)
#   R != Z  ||  D != 0            -> FAIL    rc 40  attested zero-yield cells re-walked, or
#                                                   unattested cells resumed
#   EXCESS >= Z * budget_A / 2    -> FAIL    rc 40  resume did not save the work it claims
#   otherwise                     -> PASS    rc 0
#   layout/derivation broken      -> ERROR   rc 43  never collapses to PASS or to VACUOUS
#
# Whole-line, grep -qx-able tokens (emitted on EVERY exit path, including VACUOUS and ERROR):
#   RESUME_167_SIDECARS=<S>
#   RESUME_167_ZERO_YIELD_CELLS=<Z>
#   RESUME_167_RESUMED=<R>
#   RESUME_167_DISCARDED=<D>
#   RESUME_167_NODES_A=<nodes_A>
#   RESUME_167_NODES_B=<nodes_B>
#   RESUME_167_NODES_SINGLE=<nodes_single>
#   RESUME_167_EXCESS_NODES=<EXCESS>
#   SELFTEST_RESUME_167=PASS|FAIL|VACUOUS|ERROR
# In --battery mode, additionally one line per mutant plus:
#   RESUME_167_MUTANTS_KILLED=<n>/<total>
#   SELFTEST_RESUME_167_BATTERY=PASS|FAIL|ERROR   (ERROR, rc 43: a mutant's tdir was not empty)
#
# The two tempdirs are KEPT on any non-PASS. The evidence is the directory. A non-empty
# tdir_A or tdir_B under --workdir is REFUSED (ERROR, rc 43, nothing deleted; Q-851).
#
# ============================================================================================
# MUTANTS  (--battery) — "a comparator that has never been SEEN to fail is not evidence"
# ============================================================================================
#   M0  none (positive control)                      expect PASS
#   M1  PHASE_B run by the PRE-FIX binary            expect FAIL   R==0, D==Z
#   M2  rm every shard-less sidecar                  expect VACUOUS (Z==0 rule)
#   M3  clear reserved2[0] on ONE zero-yield sidecar expect FAIL   R==Z-1, D==1
#   M4  write prior_solutions_found=5 on ONE         expect FAIL   R==Z-1, D==1
#   M5  rm ONE productive shard                      expect FAIL   D==1, sha still equal
#   M6  strip the guard lines from phase_b.log       expect VACUOUS (R+D==0 rule)
#   M7  flags byte 0xFF on ONE zero-yield sidecar    expect FAIL   R==Z-1, D==1, W==1, sha equal
#   M8  ONE zero-yield sidecar padded to 576 B, v2   expect FAIL   R==Z-1, D==0, W==1, sha equal
#
# PINNED, from the first green run (2026-09-05, c284-staget, 128 cores, depth-2 default shape,
# threads=4, PHASE_A 50M -> budget_A 16,501/cell, PHASE_B/single 200M -> budget_B 66,006/cell,
# 3,030 cells):
#     fixed binary   S=3030  Z=1933  R=1933  D=0     EXCESS=3,030       -> PASS
#     pre-fix binary S=3030  Z=1933  R=0     D=1933  EXCESS=31,897,530  -> FAIL
# EXCESS=3,030 is exactly one node per resumed cell (1,933 zero-yield + 1,097 productive), i.e.
# the captured frame's ENTER counted once by each phase. EXCESS=31,897,530 is exactly
# 1,933 x 16,501 -- every zero-yield cell re-walking its whole PHASE_A budget from zero, 63.8%%
# of PHASE_A's entire 50M budget redone. The threshold Z*budget_A/2 = 15,948,216 sits ~5,263x
# above the post-fix value and ~0.5x below the pre-fix one. Both figures are budget-dependent
# (Z was 1,961/3,030 at a 20M PHASE_A), which is why the gate re-measures Z every run and
# asserts no constant.
#
# M2 and M6 are the two that matter: they are the "passed means never looked" cases, and the
# unaugmented `--selftest-resume` passes both.
#
# M7/M8 (Q-818, 2026-09-25) are the two Q-732 reader hardenings, which until then only tests.py
# covered. M7 sets reserved2[0] to 0xFF: the reader must require the flags byte to EQUAL
# DFS_V2_FLAG_YIELD_ATTESTED, not merely contain it, so the cell is unattested and the guard
# discards it (D==1). M8 appends 136 NUL bytes (440 -> 576 B on main) and leaves the v2 stamp: the
# reader must refuse a v2 file of any size but sizeof(st), which falls through to the v1 reader,
# which also refuses it, so there is no resume at all and no guard line (R==Z-1, D==0). In both
# the cell is walked fresh and the sha must still equal single-shot's. W counts the reader's own
# WARN line for that input ("unknown flag bits" / "stamped v2 but longer than"), exactly 1.
# A pre-Q-732 reader resumes both cells as attested (R==Z, D==0, W==0 -> PASS), so both SURVIVE
# against it. They run under --battery only; pre-push's single-run legs stay M0, M3, M4.
#
# M3/M4 mutate bytes inside a sidecar. The offsets are DERIVED, never hardcoded: reserved2[16]
# is the last member of DFSCheckpointState_v2 and the writer fwrite()s exactly sizeof(st)
# bytes, so from the file size alone
#       reserved2[0]           = size - 16
#       prior_solutions_found  = size - 24
#       prior_nodes_walked     = size - 32
#       prior_budget           = size - 40
# and the derivation is CHECKED before any byte is written: prior_budget is written as the
# literal per_branch_node_limit, which this script independently reads off the checkpoint
# lines' `budget N` suffix. If they disagree the gate is ERROR, not PASS. That keeps the same
# code correct on `main` (440-byte frame) and on v4-canonical (576-byte frame) with no
# branch-specific constants.
#
# ============================================================================================
# USAGE
# ============================================================================================
#   scripts/selftest_resume_167_gate.sh --solve ./solve [--mutant M0..M8]
#                                       [--solve-phase-b ./solve_baseline]
#                                       [--workdir DIR] [--threads N]
#                                       [--nodes-a N] [--nodes-b N] [--keep]
#   scripts/selftest_resume_167_gate.sh --battery --solve ./solve --solve-phase-b ./solve_base
#
# Wall: ~1 min per run on a many-core box at the default 50M/200M shape; the battery is 9 of
# those. Runs `solve` three times per invocation — heavy; not for the orchestrator.
#
# Authored by Claude (ROAE lane, 2026-09-05). The specification it implements is Fable's
# (Q414_V4_MIRROR_AND_NONVACUITY_2026_09_04 §2), including the verdict order, the token set,
# the mutant table and the warning against prior_nodes_walked. The VACUOUS rc-42 convention is
# `--selftest-resume-d3`'s. Errors here are mine; corrections invited.

set -uo pipefail

# 🔴 THREADS was hardcoded to 4. MEASURED 2026-09-07: this box has nproc=2, so the gate ran
# 2x oversubscribed against ITSELF -- and the compile gate's selftest, running in the same push,
# also sets SOLVE_THREADS=4. A push that took 393 s at idle took 2880 s under load, and roughly
# 85% of that was contention. A gate that fights itself for cores makes its own cost look like a
# property of the work. min(4, nproc) keeps the 4 on a real VM and stops the self-contention here.
SOLVE_A=""; SOLVE_B=""; MUTANT="M0"; WORKDIR=""
_nproc=$(nproc 2>/dev/null || echo 4); THREADS=$(( _nproc < 4 ? _nproc : 4 ))
NODES_A=50000000; NODES_B=200000000; KEEP=0; BATTERY=0

usage() { sed -n '2,143p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --solve)          SOLVE_A=${2:-}; shift 2;;
    --solve-phase-b)  SOLVE_B=${2:-}; shift 2;;
    --mutant)         MUTANT=${2:-}; shift 2;;
    --workdir)        WORKDIR=${2:-}; shift 2;;
    --threads)        THREADS=${2:-}; shift 2;;
    --nodes-a)        NODES_A=${2:-}; shift 2;;
    --nodes-b)        NODES_B=${2:-}; shift 2;;
    --keep)           KEEP=1; shift;;
    --battery)        BATTERY=1; shift;;
    -h|--help)        usage;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done

[ -n "$SOLVE_A" ] || { echo "ERROR: --solve is required" >&2; exit 2; }
SOLVE_A=$(readlink -f "$SOLVE_A") || exit 2
[ -x "$SOLVE_A" ] || { echo "ERROR: $SOLVE_A is not executable" >&2; exit 2; }
if [ -n "$SOLVE_B" ]; then
  SOLVE_B=$(readlink -f "$SOLVE_B") || exit 2
  [ -x "$SOLVE_B" ] || { echo "ERROR: $SOLVE_B is not executable" >&2; exit 2; }
fi

# ---------------------------------------------------------------------- subject currency
# 🔴 --solve MUST CORRESPOND TO solve.c. Added 2026-09-08 after the sibling gate
# scripts/resume_budget_infinity_gate.sh reported FAIL — "budget 0 is being read as 'no
# constraint' instead of infinity", i.e. AN UNDERCOUNT PRESENTED AS A COMPLETE ENUMERATION —
# against a ./solve two days older than the commit that fixed exactly that (779fff4c). Measured
# both ways that night: stale binary -> FAIL, binary built from HEAD -> PASS. This gate is in the
# same position: it takes a PATH and never builds, so run by hand as `--solve ./solve` its subject
# is whatever artifact happens to be lying in the tree. pre_push_gate.sh's "CONDITIONAL #167
# zero-yield resume leg" is safe by construction (it builds ./solve_167 first); a hand run is not.
#
# ERROR, not FAIL: an unestablished subject is not a defect, and reporting it as one sends a
# reader hunting a bug that is not there. FAIL here is rc 40 and means "the #167 fix is broken";
# this exits 43, the file's existing ERROR code, which its own verdict table already documents as
# "never collapses to PASS or to VACUOUS".
#
# ONLY --solve IS CHECKED, DELIBERATELY. --solve-phase-b is the PRE-FIX baseline: mutant M1 exists
# precisely to run PHASE_B on an OLD binary and watch the gate go red. Currency-checking it would
# error on the one input that is SUPPOSED to be stale, and would disable the battery's sharpest
# mutant. Staleness is a defect in the subject and a requirement in the control.
. "$(cd "$(dirname "$0")" && pwd)/lib_binary_currency.sh"
_SRC="$(cd "$(dirname "$0")/.." && pwd)/solve.c"
if [ "${RESUME_167_ALLOW_STALE-}" != "1" ] && ! solve_binary_currency "$SOLVE_A" "$_SRC"; then
  echo "ERROR: $BINCUR_MSG" >&2
  echo "       (set RESUME_167_ALLOW_STALE=1 to override, deliberately.)" >&2
  echo "SELFTEST_RESUME_167=ERROR"
  exit 43
fi

SHA_TOOL=""
command -v sha256sum >/dev/null 2>&1 && SHA_TOOL="sha256sum"
[ -z "$SHA_TOOL" ] && command -v shasum >/dev/null 2>&1 && SHA_TOOL="shasum -a 256"
[ -n "$SHA_TOOL" ] || { echo "ERROR: no sha256 tool" >&2; exit 2; }

# ---------------------------------------------------------------------------- one gate run
# Globals set by run_gate(): G_S G_Z G_R G_D G_NA G_NB G_NS G_EXCESS G_VERDICT G_RC G_DIR G_MSG
#   and, for the battery's M7/M8 kill criteria only (no token): G_W G_SHAEQ
run_gate() {
  local mutant="$1" solve_a="$2" solve_b="$3" wd="$4"
  local tA="$wd/tdir_A" tB="$wd/tdir_B"
  G_S=-1; G_Z=-1; G_R=-1; G_D=-1; G_NA=-1; G_NB=-1; G_NS=-1; G_EXCESS=-1
  G_VERDICT=""; G_RC=0; G_DIR="$wd"; G_MSG=""; G_W=-1; G_SHAEQ=-1; G_REFUSED=0
  # Q-851: REFUSE a non-empty tdir_A / tdir_B. solve resumes whatever sub_*.dfs_state it finds
  # in its working directory and APPENDS to checkpoint_t*.txt, and every count below is read off
  # those two directories, so a rerun into a --workdir that still holds an earlier run's
  # checkpoints (a FAIL keeps them, and so does --keep) measures the earlier run as well as this
  # one. Measured 2026-09-26 on the real binary, default shape: with an earlier run's tdir_B in
  # place, the single-shot CONTROL resumed all 3,030 cells as complete, walked none, and the gate
  # printed PASS on the earlier run's control counts and sha; with its tdir_A in place, the rerun
  # walked nothing, overwrote the kept phase_a.log, and ended ERROR for an unrelated reason (two
  # budgets). Refused rather than cleared, because the directory is the caller's and the earlier
  # run's evidence is in it: nothing is deleted here.
  local _t _first
  for _t in "$tA" "$tB"; do
    _first=$(find "$_t" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)
    if [ -n "$_first" ]; then
      G_VERDICT=ERROR; G_RC=43; G_REFUSED=1
      G_MSG="$_t is not empty (it holds $(basename "$_first"), left by an earlier run?): a rerun would resume or count that run's checkpoints. Pass a fresh --workdir, or remove $_t yourself; nothing was deleted"
      return
    fi
  done
  mkdir -p "$tA" "$tB" || { G_VERDICT=ERROR; G_RC=43; G_MSG="mkdir failed"; return; }

  local common="SOLVE_THREADS=$THREADS SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 \
SOLVE_ALLOW_SUB_CANONICAL=1 SOLVE_SKIP_CANONICAL_LOCK=1 \
SOLVE_SKIP_AUTO_SELFTEST=1 SOLVE_SKIP_AUTO_MANIFEST=1"

  # ---- PHASE_A -------------------------------------------------------------------------
  ( cd "$tA" && unset SOLVE_DEPTH && \
    env $common SOLVE_NODE_LIMIT="$NODES_A" "$solve_a" 0 > phase_a.log 2>&1 )
  local rc=$?
  if [ $rc -ne 0 ]; then
    G_VERDICT=ERROR; G_RC=43; G_MSG="PHASE_A failed rc=$rc (see $tA/phase_a.log)"; return
  fi

  # ---- budget_A, read off PHASE_A's own checkpoint lines (never hardcoded) --------------
  local bA
  bA=$(find "$tA" -maxdepth 1 -name 'checkpoint_t*.txt' -exec cat {} + 2>/dev/null \
       | awk 'NF{print $NF}' | sort -u)
  if [ "$(printf '%s\n' "$bA" | grep -c .)" -ne 1 ] || [ -z "$bA" ]; then
    G_VERDICT=ERROR; G_RC=43
    G_MSG="PHASE_A produced $(printf '%s\n' "$bA" | grep -c .) distinct per-cell budgets; expected exactly 1"
    return
  fi
  case "$bA" in ''|*[!0-9]*) G_VERDICT=ERROR; G_RC=43; G_MSG="unparseable budget_A '$bA'"; return;; esac
  echo "[gate] budget_A (per-cell) = $bA   (derived from checkpoint_t*.txt, not hardcoded)"

  # ---- shard-less list BEFORE mutation, only to pick a mutation target ------------------
  local pre_zero="$wd/pre_zero.txt" pre_prod="$wd/pre_prod.txt"
  find "$tA" -maxdepth 1 -name 'sub_*.dfs_state' | sed 's/\.dfs_state$//' | sort > "$wd/_s.txt"
  find "$tA" -maxdepth 1 -name 'sub_*.bin'       | sed 's/\.bin$//'       | sort > "$wd/_b.txt"
  comm -23 "$wd/_s.txt" "$wd/_b.txt" > "$pre_zero"
  comm -12 "$wd/_s.txt" "$wd/_b.txt" > "$pre_prod"

  # ---- apply the mutant (between PHASE_A and PHASE_B) -----------------------------------
  case "$mutant" in
    M0) : ;;
    M1) [ -n "$solve_b" ] || { G_VERDICT=ERROR; G_RC=43; G_MSG="M1 needs --solve-phase-b"; return; } ;;
    M2) # remove every shard-less sidecar -> the vacuity direction
        local n=0
        while IFS= read -r stem; do [ -n "$stem" ] && rm -f "$stem.dfs_state" && n=$((n+1)); done < "$pre_zero"
        echo "[gate] M2: removed $n shard-less sidecars" ;;
    M3|M4|M7|M8)
        local target; target=$(head -n1 "$pre_zero")
        [ -n "$target" ] || { G_VERDICT=ERROR; G_RC=43; G_MSG="$mutant: no zero-yield sidecar to mutate"; return; }
        local f="$target.dfs_state" sz
        sz=$(stat -c %s "$f" 2>/dev/null) || { G_VERDICT=ERROR; G_RC=43; G_MSG="stat failed on $f"; return; }
        local off_res=$((sz-16)) off_sol=$((sz-24)) off_nod=$((sz-32)) off_bud=$((sz-40))
        # DERIVATION CHECK. prior_budget is written as the literal per_branch_node_limit; this
        # script read that same number off the checkpoint lines. If they disagree the offsets
        # are wrong and every byte written below would land somewhere unintended.
        local seen_bud
        seen_bud=$(od -A n -t d8 -j "$off_bud" -N 8 "$f" | tr -d ' \n')
        echo "[gate] $mutant target=$f size=$sz  reserved2[0]@$off_res prior_solutions_found@$off_sol prior_budget@$off_bud"
        echo "[gate] layout check: prior_budget on disk = $seen_bud vs budget_A = $bA"
        if [ "$seen_bud" != "$bA" ]; then
          G_VERDICT=ERROR; G_RC=43
          G_MSG="sidecar layout derivation FAILED (prior_budget $seen_bud != budget_A $bA) — refusing to write bytes blind"
          return
        fi
        if [ "$mutant" = "M3" ]; then
          printf '\000' | dd of="$f" bs=1 seek="$off_res" conv=notrunc status=none
          echo "[gate] M3: cleared the attestation flag on $f"
        elif [ "$mutant" = "M7" ]; then
          printf '\377' | dd of="$f" bs=1 seek="$off_res" conv=notrunc status=none
          echo "[gate] M7: set the flags byte to 0xFF on $f — unknown bits, NOT an attestation"
        elif [ "$mutant" = "M8" ]; then
          head -c 136 /dev/zero >> "$f"
          echo "[gate] M8: padded $f from $sz to $(stat -c %s "$f") bytes, still stamped v2"
        else
          printf '\005\000\000\000\000\000\000\000' | dd of="$f" bs=1 seek="$off_sol" conv=notrunc status=none
          printf '\001' | dd of="$f" bs=1 seek="$off_res" conv=notrunc status=none
          echo "[gate] M4: set prior_solutions_found=5 (flag set) on $f — attested LOSS"
        fi ;;
    M5) local target; target=$(head -n1 "$pre_prod")
        [ -n "$target" ] || { G_VERDICT=ERROR; G_RC=43; G_MSG="M5: no productive cell to mutate"; return; }
        rm -f "$target.bin"
        echo "[gate] M5: removed the productive shard $target.bin" ;;
    M6) : ;;   # applied to phase_b.log after PHASE_B
    *)  G_VERDICT=ERROR; G_RC=43; G_MSG="unknown mutant '$mutant'"; return;;
  esac

  # ---- S and Z, from the FILESYSTEM, after mutation and before PHASE_B ------------------
  # Authoritative: this is the state PHASE_B's guard will actually see. `find`, never a glob
  # (feedback_find_over_glob_for_large_dirs).
  find "$tA" -maxdepth 1 -name 'sub_*.dfs_state' | sed 's/\.dfs_state$//' | sort > "$wd/s.txt"
  find "$tA" -maxdepth 1 -name 'sub_*.bin'       | sed 's/\.bin$//'       | sort > "$wd/b.txt"
  G_S=$(grep -c . < "$wd/s.txt")
  G_Z=$(comm -23 "$wd/s.txt" "$wd/b.txt" | grep -c .)
  echo "[gate] sidecars S=$G_S  shard-less (zero-yield) Z=$G_Z  productive P=$((G_S-G_Z))"

  # ---- PHASE_B (resume) in the SAME dir -------------------------------------------------
  local sb="$solve_a"
  [ "$mutant" = "M1" ] && sb="$solve_b"
  ( cd "$tA" && unset SOLVE_DEPTH && \
    env $common SOLVE_NODE_LIMIT="$NODES_B" "$sb" 0 > phase_b.log 2>&1 )
  rc=$?
  if [ $rc -ne 0 ]; then
    G_VERDICT=ERROR; G_RC=43; G_MSG="PHASE_B failed rc=$rc (see $tA/phase_b.log)"; return
  fi

  if [ "$mutant" = "M6" ]; then
    grep -v -F '[#167-guard]' "$tA/phase_b.log" > "$tA/phase_b.log.m6" && mv "$tA/phase_b.log.m6" "$tA/phase_b.log"
    echo "[gate] M6: stripped every [#167-guard] line from phase_b.log"
  fi

  # ---- R and D, from phase_b.log, BEFORE anything is deleted ----------------------------
  # ASCII substrings only — the guard's messages carry an em-dash and the two strings are
  # disjoint by construction. Every discard variant (attested-loss and unattested) ends with
  # the same "discarding resume, walking cell fresh".
  G_R=$(grep -c -F 'checkpoint ATTESTS zero yield' "$tA/phase_b.log")
  G_D=$(grep -c -F 'discarding resume, walking cell fresh' "$tA/phase_b.log")
  echo "[gate] guard resumed R=$G_R  guard discarded D=$G_D"
  # The reader's own WARN for M7's / M8's input (0 on any other run of a correct binary).
  G_W=$(grep -c -F -e 'WARN: unknown flag bits, yield NOT attested' -e 'is stamped v2 but longer than' "$tA/phase_b.log")

  # ---- single-shot at the final budget, fresh dir ---------------------------------------
  ( cd "$tB" && unset SOLVE_DEPTH && \
    env $common SOLVE_NODE_LIMIT="$NODES_B" "$solve_a" 0 > single.log 2>&1 )
  rc=$?
  if [ $rc -ne 0 ]; then
    G_VERDICT=ERROR; G_RC=43; G_MSG="single-shot failed rc=$rc (see $tB/single.log)"; return
  fi

  # ---- budget_B, and the per-run node sums ----------------------------------------------
  local bB
  bB=$(find "$tA" -maxdepth 1 -name 'checkpoint_t*.txt' -exec cat {} + 2>/dev/null \
       | awk 'NF{print $NF}' | sort -u | grep -v -x "$bA")
  if [ "$(printf '%s\n' "$bB" | grep -c .)" -ne 1 ] || [ -z "$bB" ]; then
    G_VERDICT=ERROR; G_RC=43; G_MSG="could not isolate budget_B (got '$bB'); PHASE_A/B budgets must differ"; return
  fi
  echo "[gate] budget_B (per-cell) = $bB"

  # PHASE_B *appends* to PHASE_A's checkpoint files, so the two runs are separated by the
  # `budget N` suffix of each line. sub_nodes is a PER-RUN delta (ts->nodes - nodes_before),
  # which is exactly why EXCESS discriminates where prior_nodes_walked does not.
  # Q-951 (Codex push-path review Q835, P-04, 2026-10-03): each sum goes through node_sum, which
  # REFUSES (rc 3) instead of reading 0. The inline awk `acc+0` read 0 nodes for every run when no
  # row matched the budget or the row format drifted (no numeric "N nodes,"), so EXCESS = 0 sat
  # under any threshold and the work-saving leg PASSED on a comparison that never happened.
  G_NA=$(node_sum "$tA" "$bA") || { G_VERDICT=ERROR; G_RC=43; G_MSG="nodes_A unparseable: $G_NA"; return; }
  G_NB=$(node_sum "$tA" "$bB") || { G_VERDICT=ERROR; G_RC=43; G_MSG="nodes_B unparseable: $G_NB"; return; }
  G_NS=$(node_sum "$tB" "$bB") || { G_VERDICT=ERROR; G_RC=43; G_MSG="nodes_single unparseable: $G_NS"; return; }
  G_EXCESS=$(( G_NA + G_NB - G_NS ))
  echo "[gate] nodes_A=$G_NA nodes_B=$G_NB nodes_single=$G_NS  EXCESS=$G_EXCESS"

  # ---- shas -----------------------------------------------------------------------------
  local sha_r sha_s
  sha_r=$($SHA_TOOL "$tA/solutions.bin" 2>/dev/null | cut -d' ' -f1)
  sha_s=$($SHA_TOOL "$tB/solutions.bin" 2>/dev/null | cut -d' ' -f1)
  echo "[gate] sha resume      = ${sha_r:-<none>}"
  echo "[gate] sha single-shot = ${sha_s:-<none>}"
  G_SHAEQ=0; [ -n "$sha_r" ] && [ "$sha_r" = "$sha_s" ] && G_SHAEQ=1

  # ---- verdict, in order ----------------------------------------------------------------
  local thresh=$(( G_Z * bA / 2 ))
  if [ "$G_Z" -eq 0 ]; then
    G_VERDICT=VACUOUS; G_RC=42
    G_MSG="no zero-yield sidecar exists (S=$G_S, Z=0); the #167 path cannot be exercised at this shape"
  elif [ $(( G_R + G_D )) -eq 0 ]; then
    G_VERDICT=VACUOUS; G_RC=42
    G_MSG="Z=$G_Z sidecars are shard-less and the guard reported on none of them"
  elif [ -z "$sha_r" ] || [ "$sha_r" != "$sha_s" ]; then
    G_VERDICT=FAIL; G_RC=40
    G_MSG="resume sha differs from single-shot (the c3ad271 bug-3 class failure)"
  elif [ "$G_R" -ne "$G_Z" ] || [ "$G_D" -ne 0 ]; then
    G_VERDICT=FAIL; G_RC=40
    G_MSG="attested zero-yield cells re-walked or unattested cells resumed (R=$G_R vs Z=$G_Z, D=$G_D)"
  elif [ "$G_EXCESS" -ge "$thresh" ]; then
    G_VERDICT=FAIL; G_RC=40
    G_MSG="resume did not save the work it claims (EXCESS=$G_EXCESS >= Z*budget_A/2=$thresh)"
  else
    G_VERDICT=PASS; G_RC=0
    G_MSG="R=Z=$G_Z zero-yield cells resumed, D=0, EXCESS=$G_EXCESS < Z*budget_A/2=$thresh, sha identical"
  fi
}

# node_sum <dir> <budget>: the sum of "<N> nodes," over that dir's checkpoint_t*.txt rows whose last
# field is <budget>. rc 0 + the sum; rc 3 + a reason when no row carries the budget, or any such row
# has no numeric "<N> nodes," field -- an unparseable population is not a population of zero.
node_sum() {
  find "$1" -maxdepth 1 -name 'checkpoint_t*.txt' -exec cat {} + 2>/dev/null | awk -v b="$2" '
    $NF==b { n++; got=0
             for (i=2;i<=NF;i++) if ($i=="nodes," && $(i-1) ~ /^[0-9]+$/) { acc+=$(i-1); got=1 }
             if (!got) bad++ }
    END { if (n==0)  { print "no checkpoint row carries budget " b; exit 3 }
          if (bad>0) { print bad " of " n " budget-" b " row(s) have no numeric \"N nodes,\" field"; exit 3 }
          print acc+0 }'
}

emit_tokens() {
  printf 'RESUME_167_SIDECARS=%s\n'          "$G_S"
  printf 'RESUME_167_ZERO_YIELD_CELLS=%s\n'  "$G_Z"
  printf 'RESUME_167_RESUMED=%s\n'           "$G_R"
  printf 'RESUME_167_DISCARDED=%s\n'         "$G_D"
  printf 'RESUME_167_NODES_A=%s\n'           "$G_NA"
  printf 'RESUME_167_NODES_B=%s\n'           "$G_NB"
  printf 'RESUME_167_NODES_SINGLE=%s\n'      "$G_NS"
  printf 'RESUME_167_EXCESS_NODES=%s\n'      "$G_EXCESS"
  printf 'SELFTEST_RESUME_167=%s\n'          "$G_VERDICT"
}

# ---------------------------------------------------------------------------- single run
if [ "$BATTERY" -eq 0 ]; then
  # _wd_ours = 1 ONLY when we minted the directory ourselves. A caller-supplied
  # --workdir -- the flag the USAGE block above advertises -- belongs to the caller and is
  # never ours to `rm -rf`. Measured 2026-09-19 (Q-654): with the caller dir seeded, a
  # PASS removed precious.txt and precious_sub/ outright. The PASS cleanup below is
  # therefore narrowed to run_gate()'s own artifacts in that case, which is what the
  # battery path at the bottom of this file already does.
  wd="$WORKDIR"; _wd_ours=0
  [ -n "$wd" ] || { wd=$(mktemp -d /tmp/resume167_gate_XXXXXX); _wd_ours=1; }
  mkdir -p "$wd"
  echo "[gate] mutant=$MUTANT  solve=$SOLVE_A  phase_b=${SOLVE_B:-<same>}  workdir=$wd"
  echo "[gate] shape: threads=$THREADS nodes_A=$NODES_A nodes_B=$NODES_B"
  run_gate "$MUTANT" "$SOLVE_A" "$SOLVE_B" "$wd"
  echo "[gate] $G_VERDICT — $G_MSG"
  if [ "$G_VERDICT" = "PASS" ] && [ "$KEEP" -eq 0 ]; then
    if [ "$_wd_ours" -eq 1 ]; then
      rm -rf "$wd"
    else
      # Exactly what run_gate() creates under $wd: two dirs and six .txt files. Anything
      # else in a caller-supplied --workdir was there before us and stays.
      rm -rf "$wd/tdir_A" "$wd/tdir_B"
      rm -f "$wd/pre_zero.txt" "$wd/pre_prod.txt" "$wd/_s.txt" "$wd/_b.txt" \
            "$wd/s.txt" "$wd/b.txt"
    fi
  elif [ "$G_REFUSED" -eq 1 ]; then
    echo "[gate] refused before running anything; $wd was left exactly as it was found"
  else
    echo "[gate] evidence KEPT: $wd/tdir_A  $wd/tdir_B"
  fi
  emit_tokens
  exit "$G_RC"
fi

# ---------------------------------------------------------------------------- battery
# Each mutant is run and its verdict AND its distinguishing counts are asserted. A mutant is
# "killed" only if the gate reached the expected verdict for the expected reason.
[ -n "$SOLVE_B" ] || { echo "ERROR: --battery needs --solve-phase-b (the pre-fix baseline) for M1" >&2; exit 2; }
BROOT="$WORKDIR"
[ -n "$BROOT" ] || BROOT=$(mktemp -d /tmp/resume167_battery_XXXXXX)
mkdir -p "$BROOT"
echo "[battery] root=$BROOT  fixed=$SOLVE_A  baseline=$SOLVE_B"
# Q-851: the battery KEEPS M1..M8's trees by design, so a second battery into the same --workdir
# would run every mutant beside the first battery's checkpoints. run_gate() refuses each such
# directory, but that would be scored mutant by mutant as SURVIVED, i.e. a FAIL of the fix. Refuse
# the whole battery up front instead, as ERROR (rc 43): the subject was never measured.
_stale=""
for m in M0 M1 M2 M3 M4 M5 M6 M7 M8; do
  for _t in "$BROOT/$m/tdir_A" "$BROOT/$m/tdir_B"; do
    [ -n "$(find "$_t" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ] && _stale="$_stale $_t"
  done
done
if [ -n "$_stale" ]; then
  echo "[battery] ERROR: not empty, left by an earlier run?:$_stale" >&2
  echo "[battery] a rerun would resume or count those checkpoints. Pass a fresh --workdir; nothing was deleted." >&2
  echo 'SELFTEST_RESUME_167_BATTERY=ERROR'; exit 43
fi

killed=0; total=0; battery_ok=1
for m in M0 M1 M2 M3 M4 M5 M6 M7 M8; do
  total=$((total+1))
  wd="$BROOT/$m"; mkdir -p "$wd"
  echo ""
  echo "=========================== $m ==========================="
  run_gate "$m" "$SOLVE_A" "$SOLVE_B" "$wd"
  echo "[gate] $G_VERDICT — $G_MSG"
  emit_tokens

  exp=""; why=""
  case "$m" in
    M0) exp=PASS;    [ "$G_R" -eq "$G_Z" ] && [ "$G_D" -eq 0 ] && why=ok ;;
    M1) exp=FAIL;    [ "$G_R" -eq 0 ] && [ "$G_D" -eq "$G_Z" ] && why=ok ;;
    M2) exp=VACUOUS; [ "$G_Z" -eq 0 ] && why=ok ;;
    M3) exp=FAIL;    [ "$G_R" -eq $((G_Z-1)) ] && [ "$G_D" -eq 1 ] && why=ok ;;
    M4) exp=FAIL;    [ "$G_R" -eq $((G_Z-1)) ] && [ "$G_D" -eq 1 ] && why=ok ;;
    M5) exp=FAIL;    [ "$G_D" -eq 1 ] && [ "$G_R" -eq $((G_Z-1)) ] && why=ok ;;
    M6) exp=VACUOUS; [ $((G_R+G_D)) -eq 0 ] && why=ok ;;
    M7) exp=FAIL;    [ "$G_R" -eq $((G_Z-1)) ] && [ "$G_D" -eq 1 ] && [ "$G_W" -eq 1 ] && [ "$G_SHAEQ" -eq 1 ] && why=ok ;;
    M8) exp=FAIL;    [ "$G_R" -eq $((G_Z-1)) ] && [ "$G_D" -eq 0 ] && [ "$G_W" -eq 1 ] && [ "$G_SHAEQ" -eq 1 ] && why=ok ;;
  esac
  xtra=""; case "$m" in M7|M8) xtra=" W=$G_W SHA_EQ=$G_SHAEQ";; esac
  if [ "$G_VERDICT" = "$exp" ] && [ "$why" = "ok" ]; then
    killed=$((killed+1))
    echo "RESUME_167_MUTANT_$m=KILLED expected=$exp got=$G_VERDICT S=$G_S Z=$G_Z R=$G_R D=$G_D EXCESS=$G_EXCESS$xtra"
  else
    battery_ok=0
    echo "RESUME_167_MUTANT_$m=SURVIVED expected=$exp got=$G_VERDICT S=$G_S Z=$G_Z R=$G_R D=$G_D EXCESS=$G_EXCESS$xtra"
  fi
  # M0 is the positive control: its tree is the one that should be clean, so only it is
  # cleaned up. Every other mutant's tree is evidence of a kill and is kept.
  if [ "$m" = "M0" ] && [ "$G_VERDICT" = "PASS" ] && [ "$KEEP" -eq 0 ]; then rm -rf "$wd/tdir_A" "$wd/tdir_B"; fi
done

echo ""
printf 'RESUME_167_MUTANTS_KILLED=%d/%d\n' "$killed" "$total"
if [ "$battery_ok" -eq 1 ] && [ "$killed" -eq "$total" ]; then
  echo 'SELFTEST_RESUME_167_BATTERY=PASS'; exit 0
fi
echo 'SELFTEST_RESUME_167_BATTERY=FAIL'; exit 40
