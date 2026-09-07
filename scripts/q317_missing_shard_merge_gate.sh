#!/usr/bin/env bash
# Q-317 (4) — a shard that is ENTIRELY ABSENT must not pass the end-of-enum merge.
#
# ############################################################################
# # THIS GATE IS EXPECTED TO REPORT **FAIL** ON TODAY'S TREE.                #
# # The fix is NOT landed. A FAIL here is the gate WORKING: it is the RED    #
# # that the fix must turn green. Do not "repair" the gate, and do not add   #
# # it to any blocking hook until solve.c is fixed. If it reports ERROR,     #
# # that IS a broken gate (or a changed binary) — see the ERROR list below.  #
# ############################################################################
#
# THE DEFECT, located and MEASURED (2026-09-07, on the tree at f4a2d330).
#   solve.c's end-of-enum merge cross-references each checkpoint row's claimed
#   solution count against the shard on disk:
#
#       long long lsz_xref = gz_logical_size(expected_fname);
#       if (lsz_xref >= 0) {                 /* <-- NO else arm */
#           if (file_records < ckpt_count) { ... return 20; }
#       }
#
#   gz_logical_size() returns -1 for a file that cannot be stat'd, so a shard
#   that has been DELETED falls straight through in silence while its checkpoint
#   row still claims N records. The truncation arm beside it can only fire on a
#   file it can OPEN. Losing a whole shard — the worse failure — is the unguarded
#   one.
#
# THE LARGER DEFECT, also MEASURED, and the reason a missing-file arm alone is
# not the whole fix.
#   The cross-reference reads ONLY checkpoint.txt. Workers write to
#   checkpoint_t<tid>.txt. After a real enumeration on this box:
#       checkpoint.txt      0 lines
#       checkpoint_t0.txt   1515 lines
#       checkpoint_t1.txt   1515 lines
#   and the merge printed
#       Checkpoint cross-ref: 0 EXHAUSTED, 0 BUDGETED, 0 INTERRUPTED
#   The loop body iterated ZERO times over 3,030 real rows. So the EXISTING
#   truncation arm and any NEW missing-file arm are both dead code until the
#   cross-reference parses checkpoint_t<N>.txt. **The per-thread parse is the
#   load-bearing half of the fix, not the else arm.** (The per-thread parse
#   landed on the RESUME path only; the merge side never caught up.)
#
# WHICH LEG ISOLATES THE DEFECT — read this before trusting a green.
#   DELETE leg    : the isolating one. MEASURED today: RC=0, the shard's records
#                   silently vanish from the merge pool. This is the FAIL.
#   TRUNCATE leg  : a POSITIVE CONTROL ONLY. It is caught by the shard-scan size
#                   check ("logical size N is not a multiple of 32"), which never
#                   consults the checkpoint at all. It therefore proves NOTHING
#                   about the cross-reference — it proves only that the leg
#                   reached the merge scan and that a loud merge failure does
#                   surface through this harness as a non-zero RC. A gate that
#                   tested truncation alone would be green today and would prove
#                   nothing new.
#
# WHY THE MERGE BLOCK IS SO HARD TO REACH (four early exits, all verified in code).
#   The block sits on the `if (!fork_merge_done)` branch of the END-OF-ENUMERATION
#   handoff — NOT on the re-exec path, and NOT in the standalone `--merge`
#   implementation, which lives ~2,700 lines earlier and returns long before it.
#   It is skipped by:
#     1. a bare `./solve --merge`         (separate implementation, returns first)
#     2. SOLVE_SKIP_AUTOMERGE=1           (returns immediately after the enum)
#     3. "All N sub-branches already completed."   (returns before the merge)
#     4. dfs_iterative_enabled            (forks + execs, sets fork_merge_done=1)
#   and (4) is FORCED to 1 whenever SOLVE_NODE_LIMIT >= 1T, so **on every
#   canonical run this block is skipped by construction.** It is reachable on
#   exactly one shape: a fresh enumeration (not --merge), SOLVE_SKIP_AUTOMERGE
#   unset, at least one sub-branch still pending, and node_limit < 1T. This gate
#   builds precisely that shape — which is why it seeds a real enum and then
#   re-runs with ONE sub-branch made pending again, rather than calling --merge.
#   An earlier attempt at this fix was reverted UNPROVEN because it was tested
#   with `solve --merge`, where the arm can never fire.
#
#   Modelled on scripts/resume_budget_infinity_gate.sh (fabricated fixture,
#   two-sided, KEY=value verdict). Deliberately NOT modelled on
#   scripts/test_eviction_resume_manifest.sh, which sets SOLVE_SKIP_AUTOMERGE=1
#   and so can never reach the merge at all.
#
# COST — this is NOT a sub-second gate, and cannot be made one.
#   SOLVE_DEPTH is refused below 2 (solve.c: "must be 2 or 3"), so there is no
#   n=9-style toy enum: 3,030 depth-2 sub-branches is the floor, and the seed has
#   to be a REAL enumeration because that is the only shape that reaches the
#   merge block. MEASURED end-to-end on the 2-core orchestrator, gzip shards,
#   at the default Q317_PSB=2000:
#     whole gate   2m55 wall / 1m15 user / 21s sys      $0, local, no VM
#       seed       ~1m49  (enum ~100s + merge)  1,034 shards, 39,597 records, RC=0
#       delete leg   27s   RC=0   1,033 shards, 39,588 records   <-- the defect
#       truncate leg 39s   RC=20  "logical size 280 is not a multiple of 32"
#   Also measured at Q317_PSB=20000 (10x the budget): seed enum ~350s, 1,097
#   shards, 216,803 records; same two verdicts. Raise the budget only if you want
#   a bigger pool — it does not change what is being tested. An earlier pair of
#   legs timed 1m48/1m57 wall at 12s user under load average ~10, so wall time
#   here is mostly contention on the shared 2-core box, not work.
#
# ONE MORE MEASURED DETAIL, so nobody gates on the wrong number.
#   At Q317_PSB=20000 the deleted shard's records were ALL duplicates of
#   solutions found in other shards, so `Unique solutions` was 88,191 both with
#   and without it: the loss was invisible in the unique count. Whether the
#   unique count moves is a property of the victim, not of the defect, so this
#   gate adjudicates on the EXIT CODE and never on the unique count.
#
# VERDICT: MISSING_SHARD_MERGE=PASS|FAIL|ERROR   (exit 0 | 1 | 2)
#   PASS  the delete leg reached the merge scan AND exited non-zero.
#   FAIL  the delete leg reached the merge scan and exited 0 — the defect.
#   ERROR nothing was measured; see the ERROR list. Never reported as PASS.
#
# KNOBS: BIN (default ./solve), Q317_PSB (seed per-sub-branch budget, default
#        2000), Q317_KEEP=1 (keep the work dir), TMPDIR.
# Nothing is written inside the repo: the seed and both legs live in a temp dir.

set -uo pipefail

here=$(cd "$(dirname "$0")/.." && pwd) || exit 2
BIN=${BIN:-./solve}
case "$BIN" in
  /*) bin="$BIN" ;;
  # BIN may be repo-relative; resolving it against the repo root (not the CWD)
  # matters because every run below happens inside a temp dir. Getting this
  # wrong once made a sibling gate report FAIL for a run that never happened.
  *)  bin="$here/${BIN#./}" ;;
esac

fail_error() { echo "   [ERROR] $*"; echo "MISSING_SHARD_MERGE=ERROR"; exit 2; }

[ -x "$bin" ] || fail_error "no executable binary at $bin (set BIN=)"
command -v gzip >/dev/null 2>&1 || fail_error "gzip not found (needed to rebuild a shard for the control leg)"

PSB=${Q317_PSB:-2000}
WORK=$(mktemp -d "${TMPDIR:-/tmp}/q317_missing_shard_XXXXXX") || fail_error "mktemp failed"
cleanup() { [ "${Q317_KEEP:-0}" = "1" ] || rm -rf "$WORK"; }
trap cleanup EXIT
[ "${Q317_KEEP:-0}" = "1" ] && echo "   work dir kept at $WORK"

# One enumeration shape for the seed and both legs. Every variable that would
# route around the merge block is explicitly UNSET rather than merely not set:
#   SOLVE_SKIP_AUTOMERGE -> early return before the merge
#   SOLVE_NODE_LIMIT     -> >= 1T forces dfs_iterative_enabled=1 -> fork+exec merge
#   SOLVE_DFS_ITERATIVE  -> same fork+exec merge, set directly
# Args are `<time_limit> <threads>`; time_limit 0 = run to completion, because a
# time-limited run tags sub-branches INTERRUPTED and changes what is on disk.
run_enum() { # run_enum <dir> <logfile>
  ( cd "$1" && env -u SOLVE_SKIP_AUTOMERGE -u SOLVE_NODE_LIMIT -u SOLVE_DFS_ITERATIVE \
                    SOLVE_DEPTH=2 SOLVE_PER_SUB_BRANCH_LIMIT="$PSB" \
                    nice -n 5 "$bin" 0 2 ) > "$2" 2>&1
}

# ---------------------------------------------------------------- seed --------
echo "   seeding a real enumeration (3,030 depth-2 sub-branches, budget $PSB/branch)..."
mkdir -p "$WORK/seed" || fail_error "cannot create $WORK/seed"
run_enum "$WORK/seed" "$WORK/seed.log"
seed_rc=$?
[ "$seed_rc" -eq 0 ] || { sed -n '$p' "$WORK/seed.log"; fail_error "seed enumeration exited $seed_rc — nothing measured"; }

# ERROR, never PASS, if the seed measured nothing. A gate that adjudicates an
# empty shard pool is worse than no gate.
n_shards=$(find "$WORK/seed" -maxdepth 1 -name 'sub_*.bin' | wc -l)
[ "${n_shards:-0}" -gt 0 ] || fail_error "seed produced NO shards (sub_*.bin) — nothing to delete, nothing measured"
n_ck=$(cat "$WORK/seed"/checkpoint_t*.txt 2>/dev/null | wc -l)
[ "${n_ck:-0}" -gt 0 ] || fail_error "seed produced no checkpoint_t<N>.txt rows — nothing measured"
if [ "$(grep -c 'Found .* sub-branch files' "$WORK/seed.log")" -eq 0 ]; then
  fail_error "seed never reached the merge scan — the four early exits are not all avoided on this binary"
fi
seed_found=$(sed -n 's/.*Found \([0-9]*\) sub-branch files with \([0-9]*\) total records.*/\1 files, \2 records/p' "$WORK/seed.log" | head -1)
echo "   seed: $n_shards shards, $n_ck checkpoint rows, merge scan saw $seed_found"
echo "   seed checkpoint.txt = $(wc -l < "$WORK/seed/checkpoint.txt" 2>/dev/null || echo 0) lines  <-- the dead-loop cause"
sed -n 's/^\( *Checkpoint cross-ref:.*\)$/  \1  <-- iterations over the rows above/p' "$WORK/seed.log" | head -1

# Depth-2 rows only: the ")" immediately after orient2 excludes any depth-3 row.
rows() { cat "$WORK/seed"/checkpoint_t*.txt 2>/dev/null | \
  sed -n 's/.*pair1 \([0-9]*\) orient1 \([0-9]*\) pair2 \([0-9]*\) orient2 \([0-9]*\)).*, \([0-9]*\) solutions,.*/\1 \2 \3 \4 \5/p'; }

# PENDING cell: a row claiming 0 solutions whose shard does not exist. Its row is
# removed from the leg so ONE sub-branch is left to walk — without that the run
# hits "All N sub-branches already completed." and returns BEFORE the merge.
# Removing a 0-solution row leaves no orphan shard behind, so
# promote_orphaned_shards() has nothing to promote and cannot re-complete it.
pend=""
while read -r p1 o1 p2 o2 ns; do
  [ "$ns" = "0" ] || continue
  [ -e "$WORK/seed/sub_${p1}_${o1}_${p2}_${o2}.bin" ] && continue
  pend="${p1} ${o1} ${p2} ${o2}"; break
done < <(rows)
[ -n "$pend" ] || fail_error "no 0-solution row without a shard — cannot leave a cell pending, nothing measured"

# VICTIM cell: a row claiming >0 solutions whose shard DOES exist. This is the
# shard the legs remove or truncate; its row keeps claiming the records.
vict=""; vict_n=0
while read -r p1 o1 p2 o2 ns; do
  [ "$ns" -gt 0 ] 2>/dev/null || continue
  [ -e "$WORK/seed/sub_${p1}_${o1}_${p2}_${o2}.bin" ] || continue
  vict="sub_${p1}_${o1}_${p2}_${o2}.bin"; vict_n=$ns; break
done < <(rows)
[ -n "$vict" ] || fail_error "no >0-solution row with a shard on disk — no victim, nothing measured"
set -- $pend
pend_shard="sub_${1}_${2}_${3}_${4}.bin"
pend_pat="pair1 ${1} orient1 ${2} pair2 ${3} orient2 ${4})"
echo "   pending cell = ${pend_shard%.bin} (0 solutions)   victim shard = $vict (row claims $vict_n)"

# ---------------------------------------------------------------- legs --------
mk_leg() { # mk_leg <dir>
  cp -a "$WORK/seed" "$1" || return 1
  # Stale outputs must go, and shard_manifest.txt above all: the startup
  # auto-verify (return 22) sees the missing shard and aborts BEFORE the merge,
  # so leaving it pre-empts the very thing under test.
  rm -f "$1"/solutions.bin "$1"/solutions.sha256 "$1"/solutions.meta.json \
        "$1"/solve_results.json "$1"/shard_manifest.txt "$1"/*.log
  for f in "$1"/checkpoint_t*.txt; do
    [ -e "$f" ] || continue
    grep -vF "$pend_pat" "$f" > "$f.new" && mv "$f.new" "$f"
  done
  rm -f "$1/$pend_shard"
}

echo "   leg 1/2 DELETE  (the isolating leg)..."
mk_leg "$WORK/del" || fail_error "could not build the delete leg"
rm -f "$WORK/del/$vict" || fail_error "could not delete $vict"
run_enum "$WORK/del" "$WORK/del.log"; del_rc=$?

echo "   leg 2/2 TRUNCATE (positive control)..."
mk_leg "$WORK/trunc" || fail_error "could not build the truncate leg"
# Truncate by 8 bytes of the RECORD STREAM, not of the container. Shards are
# gzip by default and gz_logical_size() reads the 4-byte ISIZE trailer, so
# lopping bytes off a .gz yields a garbage logical size that is only usually a
# non-multiple of 32. Rebuilding the stream raw and cutting 8 bytes is exact:
# a record stream is a whole number of 32-byte records, so size-8 is congruent
# to 24 mod 32 for every possible victim. Raw shards are read fine (gzr_open
# auto-detects; SOLVE_GZIP_LEVEL=0 produces them in normal operation).
if [ "$(head -c 2 "$WORK/trunc/$vict" | od -An -tx1 | tr -d ' \n')" = "1f8b" ]; then
  gzip -dc "$WORK/trunc/$vict" > "$WORK/raw.tmp" || fail_error "gzip -dc failed on $vict"
else
  cp "$WORK/trunc/$vict" "$WORK/raw.tmp" || fail_error "cp failed on $vict"
fi
raw_sz=$(wc -c < "$WORK/raw.tmp")
[ "${raw_sz:-0}" -ge 32 ] || fail_error "victim record stream is $raw_sz bytes — too small to truncate meaningfully"
head -c "$((raw_sz - 8))" "$WORK/raw.tmp" > "$WORK/trunc/$vict" || fail_error "truncate of $vict failed"
rm -f "$WORK/raw.tmp"
run_enum "$WORK/trunc" "$WORK/trunc.log"; trunc_rc=$?

# ------------------------------------------------------------- adjudicate -----
del_reached=$(grep -c 'Found .* sub-branch files' "$WORK/del.log")
del_found=$(sed -n 's/.*Found \([0-9]*\) sub-branch files with \([0-9]*\) total records.*/\1 files, \2 records/p' "$WORK/del.log" | head -1)
del_names=$(grep -cF "$vict" "$WORK/del.log")

echo "   DELETE   leg: RC=$del_rc  merge scan saw ${del_found:-<never reached>}"
echo "   TRUNCATE leg: RC=$trunc_rc  $(sed -n 's/^\(ERROR: .*not a multiple of 32.*\)$/\1/p' "$WORK/trunc.log" | head -1)"

# The control is an ERROR condition, not a FAIL: if a shard corruption the binary
# demonstrably DOES catch fails to surface here, the harness is not measuring the
# merge and the delete leg's exit code means nothing either way.
if [ "$trunc_rc" -eq 0 ]; then
  fail_error "the TRUNCATE control exited 0 — a corruption this binary is known to catch did not surface; the legs are not reaching the merge, so nothing was measured"
fi
if [ "$(grep -cF "$vict" "$WORK/trunc.log")" -eq 0 ]; then
  fail_error "the TRUNCATE control exited $trunc_rc but never named $vict — it failed for some other reason, so nothing was measured"
fi
if [ "${del_reached:-0}" -eq 0 ]; then
  fail_error "the DELETE leg never reached the merge scan (no 'Found N sub-branch files') — one of the four early exits fired; nothing was measured"
fi

if [ "$del_rc" -eq 0 ]; then
  echo "   [FAIL] $vict was DELETED, its checkpoint row still claims $vict_n solutions,"
  echo "          and the merge completed with RC=0. The records are silently gone."
  echo "          Seed merge scan saw $seed_found; this one saw $del_found."
  echo "          Cause: solve.c's cross-reference has no else arm for a missing file,"
  echo "          AND it reads only checkpoint.txt, which a real enum leaves EMPTY —"
  echo "          so the loop never iterates and the arm would be dead even if added."
  echo "          THIS FAIL IS EXPECTED until Q-317 item (4) lands. See the header."
  echo "MISSING_SHARD_MERGE=FAIL"
  exit 1
fi

# Informational only: the fix is expected to name the file it could not find, but
# the verdict does not hinge on the wording of a diagnostic that is not yet written.
if [ "${del_names:-0}" -eq 0 ]; then
  echo "   note: the delete leg exited $del_rc but did not name $vict in its output."
fi
echo "   [PASS] a deleted shard whose checkpoint row claims $vict_n solutions"
echo "          aborted the merge (RC=$del_rc) instead of being silently dropped."
echo "MISSING_SHARD_MERGE=PASS"
exit 0
