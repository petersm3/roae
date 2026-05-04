#!/bin/bash
#
# DEPRECATION NOTICE: this bash reference script will be retired
# once the equivalent functionality lands as `solve --merge-audit-pre`
# in solve.c. When that happens, this script will be removed from
# the public repo; users should invoke the solve.c subcommand
# instead. Until then, use this script as the reference implementation.
#
# merge_audit_pre.sh — pre-merge input validation
#
# Refuses to proceed with `solve --merge` if shard inventory looks
# wrong (missing shards, corrupt files, dfs_state count anomalies).
# This catches the case where deletion / disk corruption / partial
# rsync silently leaves an incomplete shard set, which solve.c's
# --merge would otherwise process and produce a "canonical" sha
# that's actually missing solutions.
#
# Usage:
#   merge_audit_pre.sh <dir> <baseline_shard_min> <baseline_shard_max>
#                          <baseline_dfs_state_count>
# Example (Tier 1 baseline):
#   merge_audit_pre.sh /mnt/work/.../tier1_11.2T 50000 65000 158364
#
# Exit 0 = audit passed; exit 1 = audit failed (do NOT proceed with merge).

set -uo pipefail

DIR=${1:?usage: $0 <dir> <shard_min> <shard_max> <dfs_state_expected>}
SHARD_MIN=${2:?}
SHARD_MAX=${3:?}
DFS_EXPECTED=${4:?}

if [ ! -d "$DIR" ]; then
  echo "FAIL: directory $DIR does not exist"
  exit 1
fi

echo "=== merge_audit_pre $(date -u +%FT%TZ) ==="
echo "DIR=$DIR"
echo "SHARD_MIN=$SHARD_MIN SHARD_MAX=$SHARD_MAX DFS_EXPECTED=$DFS_EXPECTED"

# Check 1: shard count
ACT_SHARDS=$(find $DIR -maxdepth 1 -name 'sub_*.bin' 2>/dev/null | wc -l)
echo "[1/5] shards=$ACT_SHARDS"
if [ $ACT_SHARDS -lt $SHARD_MIN ] || [ $ACT_SHARDS -gt $SHARD_MAX ]; then
  echo "FAIL: shard count $ACT_SHARDS outside [$SHARD_MIN, $SHARD_MAX]"
  echo "  Possible causes: missing shards (deleted/incomplete rsync), or"
  echo "  unusual workload distribution. Investigate before merging."
  exit 1
fi

# Check 2: dfs_state count (within 1% of expected)
ACT_DFS=$(find $DIR -maxdepth 1 -name '*.dfs_state' 2>/dev/null | wc -l)
DFS_LO=$((DFS_EXPECTED * 99 / 100))
DFS_HI=$((DFS_EXPECTED * 101 / 100))
echo "[2/5] dfs_state=$ACT_DFS (expected $DFS_EXPECTED ±1%)"
if [ $ACT_DFS -lt $DFS_LO ] || [ $ACT_DFS -gt $DFS_HI ]; then
  echo "FAIL: dfs_state count $ACT_DFS outside [$DFS_LO, $DFS_HI]"
  echo "  Possible causes: enumeration didn't complete all cells."
  exit 1
fi

# Check 3: no zero-byte or sub-record-size shards (corruption)
TINY=$(find $DIR -maxdepth 1 -name 'sub_*.bin' -size -32c 2>/dev/null | wc -l)
echo "[3/5] tiny_shards=$TINY (size <32 bytes)"
if [ $TINY -gt 0 ]; then
  echo "FAIL: $TINY shards smaller than 32 bytes (corrupted writes)"
  find $DIR -maxdepth 1 -name 'sub_*.bin' -size -32c -printf '  %p (%s bytes)\n' 2>/dev/null | head -10
  exit 1
fi

# Check 4: all shard sizes are multiples of 32 bytes (record-aligned)
MISALIGNED=0
while IFS= read -r f; do
  SZ=$(stat -c %s "$f" 2>/dev/null)
  if [ -n "$SZ" ] && [ $((SZ % 32)) -ne 0 ]; then
    MISALIGNED=$((MISALIGNED + 1))
    [ $MISALIGNED -le 5 ] && echo "  misaligned: $f size=$SZ"
  fi
done < <(find $DIR -maxdepth 1 -name 'sub_*.bin' 2>/dev/null)
echo "[4/5] misaligned_shards=$MISALIGNED (size not multiple of 32)"
if [ $MISALIGNED -gt 0 ]; then
  echo "FAIL: $MISALIGNED shards are not record-aligned (truncated mid-record)"
  exit 1
fi

# Check 5: total raw record count summary
TOTAL_BYTES=$(find $DIR -maxdepth 1 -name 'sub_*.bin' -printf '%s\n' 2>/dev/null | \
  python3 -c 'import sys; print(sum(int(x) for x in sys.stdin) if any(True for _ in iter(lambda: None, None)) or True else 0)' 2>/dev/null)
TOTAL_BYTES=${TOTAL_BYTES:-0}
TOTAL_RECORDS=$((TOTAL_BYTES / 32))
echo "[5/5] total_bytes=$TOTAL_BYTES total_raw_records=$TOTAL_RECORDS"

echo ""
echo "=== AUDIT PASSED $(date -u +%FT%TZ) ==="
echo "Inventory OK: $ACT_SHARDS shards, $ACT_DFS dfs_state files,"
echo "  $TOTAL_RECORDS raw records pre-dedup. Safe to proceed with merge."
exit 0
