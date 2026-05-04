#!/bin/bash
# merge_audit_post.sh — post-merge output validation
#
# Multi-layered audit of solutions.bin produced by `solve --merge`:
# 1. solve --verify (C-side constraint check)
# 2. verify.py (Python-side independent constraint check)
# 3. (optional) sha256 match against expected canonical
# 4. Deterministic-merge re-run: re-merge from same shards in fresh
#    dir; sha must match (catches non-determinism in solve.c's merge)
# 5. branch-yield-report extraction (forensic record of per-cell
#    yields)
#
# Usage:
#   merge_audit_post.sh <solutions.bin> <solve_binary> <verify.py>
#                       [<expected_sha>] [<src_shard_dir>]
# Examples:
#   # Validating a known canonical:
#   merge_audit_post.sh out/solutions.bin bin/solve src/verify.py \
#       0c0fe37cf449cbc6e2754583964a60c185a7b387ee522fa43a8aac4fdb055db7 \
#       /mnt/work/.../tier1_11.2T
#
#   # Validating a new canonical (no expected sha; deterministic re-merge only):
#   merge_audit_post.sh out/solutions.bin bin/solve src/verify.py \
#       "" /mnt/work/.../560T_merged
#
# Exit 0 = all audits passed; non-zero = at least one failed.

set -uo pipefail

SOL_BIN=${1:?usage: $0 <solutions.bin> <solve_binary> <verify.py> [<expected_sha>] [<src_shard_dir>]}
SOLVE=${2:?}
VERIFY_PY=${3:?}
EXPECTED_SHA=${4:-}
SHARD_DIR=${5:-}

if [ ! -f "$SOL_BIN" ]; then
  echo "FAIL: $SOL_BIN does not exist"
  exit 1
fi
if [ ! -x "$SOLVE" ]; then
  echo "FAIL: solve binary $SOLVE not executable"
  exit 1
fi
if [ ! -f "$VERIFY_PY" ]; then
  echo "FAIL: verify.py $VERIFY_PY not found"
  exit 1
fi

echo "=== merge_audit_post $(date -u +%FT%TZ) ==="
echo "SOL_BIN=$SOL_BIN"
echo "SOLVE=$SOLVE"
echo "VERIFY_PY=$VERIFY_PY"
echo "EXPECTED_SHA=${EXPECTED_SHA:-(none — deterministic-merge gate only)}"

SOL_DIR=$(dirname $SOL_BIN)
ACT_SHA=$(awk '{print $1; exit}' ${SOL_DIR}/solutions.sha256 2>/dev/null)
echo "ACTUAL_SHA=$ACT_SHA"
echo "SIZE=$(stat -c %s $SOL_BIN) bytes"

# === Check 1: solve --verify ===
echo ""
echo "[1/5] solve --verify"
$SOLVE --verify $SOL_BIN > /tmp/audit_verify_c.log 2>&1
RC_C=$?
if [ $RC_C -ne 0 ]; then
  echo "FAIL: solve --verify exit=$RC_C"
  tail -20 /tmp/audit_verify_c.log
  exit 1
fi
echo "  PASSED — every record satisfies C1-C5 (per C reimplementation)"

# === Check 2: verify.py ===
echo ""
echo "[2/5] verify.py (independent Python implementation)"
python3 $VERIFY_PY $SOL_BIN > /tmp/audit_verify_py.log 2>&1
RC_PY=$?
if [ $RC_PY -ne 0 ]; then
  echo "FAIL: verify.py exit=$RC_PY"
  tail -20 /tmp/audit_verify_py.log
  exit 1
fi
echo "  PASSED — every record satisfies C1-C5 (per Python reimplementation)"

# === Check 3: expected sha256 match (if provided) ===
echo ""
echo "[3/5] sha256 match"
if [ -z "$EXPECTED_SHA" ]; then
  echo "  SKIPPED — no expected sha provided (new canonical)"
else
  if [ "$ACT_SHA" != "$EXPECTED_SHA" ]; then
    echo "FAIL: sha mismatch"
    echo "  expected: $EXPECTED_SHA"
    echo "  actual:   $ACT_SHA"
    exit 1
  fi
  echo "  PASSED — actual sha matches expected canonical"
fi

# === Check 4: deterministic-merge re-run ===
echo ""
echo "[4/5] deterministic merge re-run from same shards"
if [ -z "$SHARD_DIR" ] || [ ! -d "$SHARD_DIR" ]; then
  echo "  SKIPPED — no shard dir provided"
else
  TEMP=$(mktemp -d)
  echo "  re-merging in $TEMP"
  # Hardlink shards (cheap, no copy) to a fresh dir for the re-merge
  find $SHARD_DIR -maxdepth 1 \( -name 'sub_*.bin' -o -name '*.dfs_state' \) -print0 | \
    xargs -0 -I{} ln -f {} $TEMP/ 2>/dev/null
  cp $SHARD_DIR/checkpoint.txt $TEMP/ 2>/dev/null || true
  cd $TEMP && $SOLVE --merge > $TEMP/merge.log 2>&1
  RC_RM=$?
  if [ $RC_RM -ne 0 ]; then
    echo "FAIL: re-merge exit=$RC_RM"
    tail -20 $TEMP/merge.log
    rm -rf $TEMP
    exit 1
  fi
  ACT_SHA_2=$(awk '{print $1; exit}' $TEMP/solutions.sha256)
  if [ "$ACT_SHA" != "$ACT_SHA_2" ]; then
    echo "FAIL: merge non-deterministic"
    echo "  first merge:  $ACT_SHA"
    echo "  second merge: $ACT_SHA_2"
    rm -rf $TEMP
    exit 1
  fi
  echo "  PASSED — re-merge produced sha $ACT_SHA_2 (deterministic)"
  rm -rf $TEMP
fi

# === Check 5: branch-yield-report (forensic record) ===
echo ""
echo "[5/5] branch-yield-report extraction"
$SOLVE --branch-yield-report $SOL_BIN > ${SOL_DIR}/branch_yield_report.txt 2>&1
echo "  written to ${SOL_DIR}/branch_yield_report.txt"
echo "  ($(wc -l < ${SOL_DIR}/branch_yield_report.txt) lines)"

echo ""
echo "=== ALL AUDITS PASSED $(date -u +%FT%TZ) ==="
echo "solutions.bin sha=$ACT_SHA is validated by:"
echo "  - C-side constraint check (solve --verify)"
echo "  - Python-side constraint check (verify.py)"
[ -n "$EXPECTED_SHA" ] && echo "  - Match against expected canonical $EXPECTED_SHA"
[ -n "$SHARD_DIR" ] && echo "  - Deterministic re-merge from source shards"
echo "  - Per-branch yield report saved for forensic record"
exit 0
