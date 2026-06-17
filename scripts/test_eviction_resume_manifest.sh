#!/bin/bash
# test_eviction_resume_manifest.sh — regression test for #164 (the #163-family
# eviction-resume false-abort).
#
# Reproduces the EXACT post-eviction state deterministically (no kill-timing
# dependence): shards present + a shard_manifest.txt that DIVERGES from them +
# per-cell .dfs_state present (the "interrupted / in-progress" signal). This is
# byte-for-byte the situation a Spot eviction leaves behind — the prior run
# advanced shards past the startup manifest snapshot and died before its clean-
# end re-emit.
#
# Asserts BOTH branches of the #164 fix:
#   POSITIVE (resume): .dfs_state present  -> startup verify is ADVISORY, enum
#                      proceeds, NO exit 22.   (This is the bug we fixed.)
#   NEGATIVE (fresh):  .dfs_state removed   -> startup verify is FATAL, exit 22.
#                      (Proves the genuine tamper tripwire is preserved.)
#
# Before #164 the POSITIVE case exited 22 (false-abort) — so this test FAILS on
# the old binary and PASSES on the fixed one: a true regression gate.
#
# Usage: scripts/test_eviction_resume_manifest.sh [path-to-solve-binary]
#        default binary: ./solve   (build first; sha-neutral, any build works)
set -uo pipefail

SOLVE_BIN="${1:-./solve}"
[ -x "$SOLVE_BIN" ] || { echo "FAIL: solve binary not executable: $SOLVE_BIN"; exit 1; }
SOLVE_BIN="$(readlink -f "$SOLVE_BIN")"

WORK="$(mktemp -d /tmp/roae_evict_test_XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1

# Common tiny-enum env: depth-2 (3,030 sub-branches), small PER-SUB-BRANCH budget
# so it returns fast and every cell is budget-limited (guarantees .dfs_state
# frontiers get written). Using SOLVE_PER_SUB_BRANCH_LIMIT (not SOLVE_NODE_LIMIT)
# also suppresses the sub-canonical 1T gate — this is an intentional within-code-
# state test, not a canonical run.
ENUM_ENV=(SOLVE_DEPTH=2 SOLVE_THREADS=4 SOLVE_PER_SUB_BRANCH_LIMIT=5000
          SOLVE_SKIP_AUTOMERGE=1 SOLVE_SKIP_IOPS_CHECK=1 SOLVE_SKIP_DISK_CHECK=1)

echo "=== Phase 1: seed a run dir (shards + matching manifest) ==="
env "${ENUM_ENV[@]}" "$SOLVE_BIN" 0 4 > p1.log 2>&1
nbin=$(find . -maxdepth 1 -name 'sub_*.bin' -type f | wc -l)
[ -f shard_manifest.txt ] || env "${ENUM_ENV[@]}" "$SOLVE_BIN" --emit-shard-manifest >/dev/null 2>&1
echo "  shards=$nbin  manifest_lines=$(wc -l < shard_manifest.txt 2>/dev/null || echo 0)"
if [ "$nbin" -lt 1 ] || [ ! -s shard_manifest.txt ]; then
    echo "FAIL: Phase 1 did not produce shards + manifest (see $WORK/p1.log)"; tail -20 p1.log; exit 1
fi

# Construct the resume signal directly: resuming_in_progress() (#164) keys on the
# PRESENCE of any *.dfs_state (the per-cell DFS resume frontier a Spot eviction
# leaves behind). We create one marker rather than depend on enum cleanup
# behavior — what we are regression-testing is the verify's branch decision, not
# the checkpoint writer. Combined with a divergent manifest below, this is
# byte-for-byte the precondition a mid-walk eviction produces.
touch sub_0_0_0_0.dfs_state

echo "=== Phase 2: force the manifest to DIVERGE from a shard (simulate advance) ==="
# Flip the recorded sha on the first manifest line: the on-disk shard now differs
# from its snapshot, exactly as a re-walked / advanced shard would.
awk 'NR==1{ n=split($0,a,"\t"); s=a[3]; c=substr(s,1,1); nc=(c=="a"?"b":"a"); a[3]=nc substr(s,2); print a[1]"\t"a[2]"\t"a[3]; next }1' \
    shard_manifest.txt > shard_manifest.txt.tmp && mv shard_manifest.txt.tmp shard_manifest.txt
echo "  corrupted line 1 sha in manifest; .dfs_state resume signal present"

echo "=== POSITIVE (resume): expect ADVISORY, NO exit 22 ==="
env "${ENUM_ENV[@]}" "$SOLVE_BIN" 0 4 > p2_resume.log 2>&1; rc_pos=$?
adv=$(grep -c "auto-verify-manifest ADVISORY" p2_resume.log)
echo "  exit=$rc_pos  advisory_lines=$adv"
if [ "$rc_pos" -eq 22 ]; then
    echo "FAIL: resume false-aborted with exit 22 (#163 not fixed). See $WORK/p2_resume.log"
    grep -iE 'verify-manifest|DIVERGED|ERROR' p2_resume.log | head; exit 1
fi
if [ "$adv" -lt 1 ]; then
    echo "FAIL: expected an ADVISORY verify line on resume; not found. See $WORK/p2_resume.log"; exit 1
fi

echo "=== NEGATIVE control (fresh start): remove .dfs_state, expect FATAL exit 22 ==="
# Re-seed (Phase 2's resume may have re-emitted/cleared state) then strip .dfs_state.
rm -f *.dfs_state
# Re-corrupt the manifest (resume re-emitted a fresh, matching one).
awk 'NR==1{ n=split($0,a,"\t"); s=a[3]; c=substr(s,1,1); nc=(c=="a"?"b":"a"); a[3]=nc substr(s,2); print a[1]"\t"a[2]"\t"a[3]; next }1' \
    shard_manifest.txt > shard_manifest.txt.tmp && mv shard_manifest.txt.tmp shard_manifest.txt
ndfs2=$(find . -maxdepth 1 -name '*.dfs_state' -type f | wc -l)
env "${ENUM_ENV[@]}" "$SOLVE_BIN" 0 4 > p3_fresh.log 2>&1; rc_neg=$?
echo "  dfs_state=$ndfs2  exit=$rc_neg"
if [ "$rc_neg" -ne 22 ]; then
    echo "FAIL: fresh-start divergence should be FATAL (exit 22); got $rc_neg. Tamper tripwire broken. See $WORK/p3_fresh.log"
    grep -iE 'verify-manifest|DIVERGED|ERROR' p3_fresh.log | head; exit 1
fi

echo
echo "PASS — #164 regression: resume DIVERGED is advisory (exit $rc_pos, not 22);"
echo "       fresh-start DIVERGED stays fatal (exit 22). Tripwire preserved."
exit 0
