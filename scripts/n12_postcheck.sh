#!/usr/bin/env bash
# n12_postcheck.sh — the INDEPENDENT checks of a decomp_certify_v3 run (the n=12 run plan's §5, with
# Fable's pre-publication items P4/P8).  Run on the pulled artifacts, never on a run still in flight.
#
#   usage: n12_postcheck.sh <source.cnf> <workdir> <run.log> <expected_total>
#
# Legs (each a whole-line token; N12_POSTCHECK=PASS only if every leg passes):
#   1. RESULT_LINE      run.log carries `DECOMP_RESULT=PASS (certified …)` — P8: nothing below is
#                       computed for a stopped or failed run; a partial ledger is never summed.
#   2. SUM_AWK          awk (a different program from the driver) re-adds the LEAF counts = expected.
#   3. ROUTES           every LEAF route is CPOG or DRAT0 (D4ONLY absent).
#   4. PARTITION_ALL    every SPLIT regenerated and witnessed; proofs.tsv shas = regenerated pieces.
#   5. TAILS            every CPOG leaf's chk.tail has a `CHECK: FULL-PROOF SUCCESS` line and a
#                       `CHECK: Regular model count = <ledger count>` line; every DRAT0 leaf's dt.tail
#                       has `s VERIFIED` and its cad.tail reports rc=20.
#   6. SPLIT_REASONS    every `needs split (…)` reason in run.log is one of the resource forms
#                       (d4 rc=N, cadical rc=N, cpog-gen rc=N, CPOG projection …, cpog-check
#                       killed/incomplete rc=N); any other reason is printed for Fable to read.
#   7. BINDING          source.sha256 in the workdir = sha256 of the source CNF given here.
set -uo pipefail
SRC=$1; WD=$2; LOG=$3; EXP=$4
HERE=$(cd "$(dirname "$0")" && pwd)
L=$WD/ledger.tsv; P=$WD/proofs.tsv
fail=0
leg(){ printf 'N12_%s=%s\n' "$1" "$2"; [ "$2" = PASS ] || fail=1; }

if grep -q '^DECOMP_RESULT=PASS (certified' "$LOG"; then leg RESULT_LINE PASS; else
  leg RESULT_LINE FAIL; echo "   no certified PASS line in $LOG: a stopped or failed run; nothing is summed"; echo "N12_POSTCHECK=FAIL"; exit 1; fi

read -r n s < <(awk -F'\t' '$1=="LEAF"{s+=$4; n++} END{print n+0, s+0}' "$L")
echo "   awk: LEAF rows=$n sum=$s expected=$EXP"
[ "$s" = "$EXP" ] && leg SUM_AWK PASS || leg SUM_AWK FAIL
grep -qx "DECOMP_TOTAL=$EXP" "$LOG" && leg TOTAL_LINE PASS || leg TOTAL_LINE FAIL

bad=$(awk -F'\t' '$1=="LEAF" && $3!="CPOG" && $3!="DRAT0"' "$L" | wc -l)
[ "$bad" -eq 0 ] && leg ROUTES PASS || { echo "   $bad uncertified LEAF rows"; leg ROUTES FAIL; }

python3 "$HERE/n12_partition_all.py" "$SRC" "$WD" > "$WD/partition_all.out" 2>&1; prc=$?
grep -v '^PARTITION_SPLIT ' "$WD/partition_all.out" | sed 's/^/   /'
if [ "$prc" -eq 0 ] && grep -qx 'PARTITION_ALL=PASS' "$WD/partition_all.out"; then leg PARTITION_ALL PASS; else leg PARTITION_ALL FAIL; fi

# 5. per-leaf verdict lines in the kept tails
tails_ok=1; miss=0
while IFS=$'\t' read -r kind tag route count; do
  [ "$kind" = LEAF ] || continue
  d=$WD/$tag
  # Verdict lines are matched with every CR removed first: real drat-trim writes `\rs VERIFIED` (CR BEFORE the
  # verdict; measured on the worker 2026-11-05, `cat -A` -> `^Ms VERIFIED$`), and GNU grep does not read `\r` in a
  # pattern as a carriage return (the 2026-11-05 preflight read all six DRAT0 leaves as unverified for that reason).
  # (No `tr | grep -q` pipeline: under pipefail grep -q's early exit can SIGPIPE tr and read a present line as
  #  absent -- the race the pipefail sweep names "false-fail(present-check)"; it fired once in the red test.)
  if [ "$route" = CPOG ]; then
    body=$(tr -d '\r' < "$d/chk.tail" 2>/dev/null)
    grep -q '^CHECK: FULL-PROOF SUCCESS' <<<"$body" &&
    grep -qx "CHECK: Regular model count = $count" <<<"$body" || { tails_ok=0; miss=$((miss+1)); }
  elif [ "$route" = DRAT0 ]; then
    body=$(tr -d '\r' < "$d/dt.tail" 2>/dev/null)
    grep -qx 's VERIFIED' <<<"$body" &&
    grep -q '^\[stream bytes=[0-9]* rc=20 ' "$d/cad.tail" 2>/dev/null || { tails_ok=0; miss=$((miss+1)); }
  fi
done < "$L"
[ "$tails_ok" -eq 1 ] && leg TAILS PASS || { echo "   $miss leaves without their verdict lines"; leg TAILS FAIL; }

# 6. split reasons
other=$(grep -o 'needs split ([^)]*)' "$LOG" | sed 's/needs split (//; s/)$//' \
        | grep -vE '^(d4 rc=-?[0-9]+|cadical rc=-?[0-9]+|cpog-gen rc=-?[0-9]+|CPOG projection [0-9]+MB > disk gate [0-9]+MB|cpog-check killed/incomplete rc=-?[0-9]+|drat-trim not VERIFIED \(rc=-?[0-9]+\))$' \
        | sort | uniq -c)
if [ -z "$other" ]; then leg SPLIT_REASONS PASS; else echo "   NON-RESOURCE split reasons (Fable reads these):"; echo "$other"; leg SPLIT_REASONS FAIL; fi

# 7. binding
rec=$(cut -d' ' -f1 "$WD/source.sha256" 2>/dev/null); got=$(sha256sum "$SRC" | cut -d' ' -f1)
[ -n "$rec" ] && [ "$rec" = "$got" ] && leg BINDING PASS || leg BINDING FAIL

if [ "$fail" -eq 0 ]; then echo "N12_POSTCHECK=PASS"; else echo "N12_POSTCHECK=FAIL"; exit 1; fi
