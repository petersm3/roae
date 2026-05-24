#!/usr/bin/env bash
# perf_bench.sh — standardized paired-perf bench for solve.c
#
# Produces an entry suitable for `documentation/PERFORMANCE_HISTORY.md`.
#
# Methodology fixed by this script (do not vary without documenting why):
#   - Single D128als_v7 Spot in westus3 (consistent SKU pool; see
#     feedback_preflight_throttle_probe for the same-SKU 2× variance pattern).
#   - Two builds compared head-to-head on the same VM (Build N = control,
#     Build U = treatment); a single VM removes inter-machine variance.
#   - Page-cache flushed (`echo 3 > /proc/sys/vm/drop_caches`) between paired runs.
#   - Enum-only wall time captured around the `--branch` command, BEFORE
#     `--merge`. Merge wall is captured separately as a correctness-gate cost,
#     not a perf metric.
#   - Multi-scale: 1B-node smoke + 1T-node full bench by default.
#   - Output: JSON line to stdout that drops into a PERFORMANCE_HISTORY.md entry.
#
# Usage:
#   perf_bench.sh --control-commit <sha> --treatment-commit <sha> [--treatment-pgo]
#                 [--scale 1B|1T|11.2T] [--branch <p> <o>] [--threads N]
#                 [--pgo-workload "<cmd>"] [--keep-vm]
#
# Cost (D128als_v7 Spot ~$0.95/hr westus3):
#   - 1B scale: ~$0.10 (≤10 min wall)
#   - 1T scale: ~$2-3 (~3h wall: 2 enum + 1 merge)
#   - 11.2T scale: ~$10-15 (~12h wall)

set -uo pipefail
exec > >(tee /tmp/perf_bench_$$.log) 2>&1

# ---------- argparse ----------
CONTROL_COMMIT=""
TREATMENT_COMMIT=""
TREATMENT_PGO=0
SCALE=1T
BRANCH_PAIR=24
BRANCH_ORIENT=0
THREADS=128
PGO_WORKLOAD="SOLVE_NODE_LIMIT=200000000 SOLVE_DEPTH=3 SOLVE_DFS_ITERATIVE=1 SOLVE_THREADS=8 ./solve_inst --branch 25 1"
KEEP_VM=0

while [ $# -gt 0 ]; do
    case "$1" in
        --control-commit) CONTROL_COMMIT="$2"; shift 2 ;;
        --treatment-commit) TREATMENT_COMMIT="$2"; shift 2 ;;
        --treatment-pgo) TREATMENT_PGO=1; shift ;;
        --scale) SCALE="$2"; shift 2 ;;
        --branch) BRANCH_PAIR="$2"; BRANCH_ORIENT="$3"; shift 3 ;;
        --threads) THREADS="$2"; shift 2 ;;
        --pgo-workload) PGO_WORKLOAD="$2"; shift 2 ;;
        --keep-vm) KEEP_VM=1; shift ;;
        *) echo "Unknown arg: $1"; exit 2 ;;
    esac
done

[ -z "$CONTROL_COMMIT" ]   && { echo "Required: --control-commit <sha>"; exit 2; }
[ -z "$TREATMENT_COMMIT" ] && { echo "Required: --treatment-commit <sha>"; exit 2; }

case "$SCALE" in
    1B)    NODE_LIMIT=1000000000      ; VM_SIZE=Standard_D8als_v7  ; DISK_GB=32  ;;
    1T)    NODE_LIMIT=1000000000000   ; VM_SIZE=Standard_D128als_v7; DISK_GB=128 ;;
    11.2T) NODE_LIMIT=11200000000000  ; VM_SIZE=Standard_D128als_v7; DISK_GB=256 ;;
    *) echo "Unknown scale: $SCALE (use 1B / 1T / 11.2T)"; exit 2 ;;
esac

LAUNCH_ID=$(date -u +%H%M)
RG="RG-PERFBENCH-${LAUNCH_ID}"
VM="perfbench-${LAUNCH_ID}"
LOC=westus3
ADMIN=azureuser
REPO=$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)

emit() { printf '[%s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }
teardown() {
    [ $KEEP_VM -eq 1 ] && { emit "KEEP-VM requested; not tearing down $RG"; return; }
    emit "TEARDOWN $RG"
    az group delete -n "$RG" --yes --no-wait 2>&1 | sed 's/^/  /' || true
}

emit "==================================="
emit "perf_bench.sh — paired solve.c perf bench"
emit "  control:   $CONTROL_COMMIT"
emit "  treatment: $TREATMENT_COMMIT (PGO=$TREATMENT_PGO)"
emit "  scale: $SCALE ($NODE_LIMIT nodes), branch $BRANCH_PAIR $BRANCH_ORIENT"
emit "  vm: $VM_SIZE Spot @ $LOC, disk ${DISK_GB}GB, threads $THREADS"
emit "==================================="

# ---------- provision ----------
emit "STEP 1: Provision $RG"
az group create -n "$RG" -l "$LOC" --query name -o tsv >/dev/null
az network vnet create -g "$RG" -n vnet --address-prefix 10.0.0.0/16 \
    --subnet-name subnet --subnet-prefix 10.0.0.0/24 --query name -o tsv >/dev/null
az vm create -g "$RG" -n "$VM" --image Ubuntu2404 --size "$VM_SIZE" \
    --priority Spot --eviction-policy Deallocate --max-price -1 \
    --admin-username "$ADMIN" --ssh-key-values "$HOME/.ssh/id_rsa.pub" \
    --vnet-name vnet --subnet subnet --public-ip-sku Standard --nsg-rule SSH \
    --os-disk-size-gb "$DISK_GB" --storage-sku StandardSSD_LRS \
    --query priority -o tsv 2>&1 | sed 's/^/  /'

echo "$(date -u +%FT%TZ) $VM $RG perf-bench-${SCALE}" >> /tmp/claude_session_vms.txt

VM_IP=$(az vm show -d -g "$RG" -n "$VM" --query publicIps -o tsv)
emit "  vm_ip=$VM_IP"

SSH="ssh -i $HOME/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o UserKnownHostsFile=/dev/null"
SCP="scp -i $HOME/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for i in $(seq 1 30); do $SSH "$ADMIN@$VM_IP" true 2>/dev/null && { emit "  ssh ready"; break; }; sleep 5; done
$SSH "$ADMIN@$VM_IP" true || { emit "FATAL: ssh never came up"; teardown; exit 1; }

# ---------- build ----------
emit "STEP 2: Install + copy source + build both binaries"
$SSH "$ADMIN@$VM_IP" 'sudo apt-get update -qq && sudo apt-get install -y -qq build-essential' 2>&1 | tail -1 | sed 's/^/  /'

git -C "$REPO" show "${CONTROL_COMMIT}:solve.c"   > /tmp/solve_ctl_${CONTROL_COMMIT}.c
git -C "$REPO" show "${TREATMENT_COMMIT}:solve.c" > /tmp/solve_trt_${TREATMENT_COMMIT}.c
$SCP /tmp/solve_ctl_${CONTROL_COMMIT}.c   "$ADMIN@$VM_IP:solve_ctl.c" >/dev/null
$SCP /tmp/solve_trt_${TREATMENT_COMMIT}.c "$ADMIN@$VM_IP:solve_trt.c" >/dev/null

$SSH "$ADMIN@$VM_IP" "
    set -e
    # Build N (control)
    gcc -O3 -flto -pthread -fopenmp -march=native -DGIT_HASH=\\\"${CONTROL_COMMIT}\\\" -o solve_N solve_ctl.c -lm 2>&1 | tail -2
    sha256sum solve_N
    ./solve_N --selftest 2>&1 | tail -2

    # Build U (treatment)
    if [ $TREATMENT_PGO -eq 1 ]; then
        # PGO discipline (codified after the 2026-05-24 silent no-PGO incident):
        #  1) Pass 1 and Pass 2 build to the SAME output binary name, then
        #     rename. Under -flto, .gcda lookup keys on the binary name; if
        #     the two passes use different output names, Pass 2 misses the
        #     profile data and silently falls back to no-PGO.
        #  2) -Werror=missing-profile turns the silent fallback into a hard
        #     build failure. If a future change breaks PGO path resolution,
        #     this fails the build instead of producing a non-PGO binary.
        #  3) Assert .gcda count > 0 between passes — verifies Pass 1
        #     actually wrote profile data before Pass 2 proceeds.
        #  See scripts/build_pgo.sh for the canonical reusable form.
        rm -rf profdir && mkdir profdir
        gcc -O3 -flto -pthread -fopenmp -march=native -fprofile-generate=\$PWD/profdir \\
            -DGIT_HASH=\\\"${TREATMENT_COMMIT}\\\" -o solve_U solve_trt.c -lm 2>&1 | tail -2
        mv solve_U solve_inst
        ./solve_inst --selftest > /dev/null 2>&1
        # PGO workload: representative hot paths
        $PGO_WORKLOAD > /tmp/pgo_workload.log 2>&1 || true
        # Assert profile data was produced before Pass 2
        GCDA=\$(find \$PWD/profdir -name '*.gcda' | wc -l)
        if [ \"\$GCDA\" -eq 0 ]; then
            echo \"FATAL: PGO Pass 1 produced no .gcda files\" >&2
            exit 1
        fi
        echo \"  PGO Pass 1: \$GCDA .gcda files\"
        gcc -O3 -flto -pthread -fopenmp -march=native \\
            -fprofile-use=\$PWD/profdir -fprofile-correction \\
            -Werror=missing-profile \\
            -DGIT_HASH=\\\"${TREATMENT_COMMIT}\\\" -o solve_U solve_trt.c -lm 2>&1 | tail -3
    else
        gcc -O3 -flto -pthread -fopenmp -march=native -DGIT_HASH=\\\"${TREATMENT_COMMIT}\\\" -o solve_U solve_trt.c -lm 2>&1 | tail -2
    fi
    sha256sum solve_U
    ./solve_U --selftest 2>&1 | tail -2
" 2>&1 | sed 's/^/  /'

# ---------- paired run ----------
emit "STEP 3: Paired enum-only runs"

# Single function: page-cache-flushed run, captures enum_wall (not merge)
# Args: $1 = build label (N or U), $2 = node limit
run_enum_only() {
    local BUILD=$1
    $SSH "$ADMIN@$VM_IP" "
        set +e
        rm -rf run_$BUILD && mkdir run_$BUILD && cd run_$BUILD
        sync
        echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true
        START=\$(date +%s%N)
        SOLVE_NODE_LIMIT=$NODE_LIMIT SOLVE_DEPTH=3 SOLVE_DFS_ITERATIVE=1 \\
            SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=$THREADS SOLVE_SKIP_AUTOMERGE=1 \\
            ../solve_$BUILD --branch $BRANCH_PAIR $BRANCH_ORIENT > solve.log 2>&1
        ENUM_RC=\$?
        END=\$(date +%s%N)
        ENUM_WALL_NS=\$((END - START))
        echo \"BUILD $BUILD enum_wall_ns=\${ENUM_WALL_NS}\"
        echo \"BUILD $BUILD enum_rc=\${ENUM_RC}\"
        # Merge separately (NOT counted toward speedup)
        if [ \$ENUM_RC -eq 0 ]; then
            MSTART=\$(date +%s%N)
            ../solve_$BUILD --merge > merge.log 2>&1
            MEND=\$(date +%s%N)
            MERGE_WALL_NS=\$((MEND - MSTART))
            echo \"BUILD $BUILD merge_wall_ns=\${MERGE_WALL_NS}\"
            sha256sum solutions.bin 2>/dev/null | awk '{print \"BUILD $BUILD sha=\" \$1}'
            BYTES=\$(stat -c %s solutions.bin 2>/dev/null || echo 0)
            echo \"BUILD $BUILD records=\$(( (BYTES - 32) / 32 ))\"
        fi
    "
}

run_enum_only N 2>&1 | sed 's/^/  /'
run_enum_only U 2>&1 | sed 's/^/  /'

# ---------- collect ----------
emit "STEP 4: Collect results + emit JSON"

OUTPUT=$($SSH "$ADMIN@$VM_IP" "
    for B in N U; do
        cd run_\$B
        ENUM_NS=\$(grep 'enum_wall_ns=' solve.log 2>/dev/null || true)
        echo \"\$B \$ENUM_NS\"
        cd ..
    done
" 2>&1)
# Actually, the wall lines went to the orchestrator log, not solve.log. Parse them from stdout.
ENUM_N_NS=$(grep "BUILD N enum_wall_ns=" /tmp/perf_bench_$$.log | tail -1 | sed 's/.*=//')
ENUM_U_NS=$(grep "BUILD U enum_wall_ns=" /tmp/perf_bench_$$.log | tail -1 | sed 's/.*=//')
MERGE_N_NS=$(grep "BUILD N merge_wall_ns=" /tmp/perf_bench_$$.log | tail -1 | sed 's/.*=//')
MERGE_U_NS=$(grep "BUILD U merge_wall_ns=" /tmp/perf_bench_$$.log | tail -1 | sed 's/.*=//')
SHA_N=$(grep "BUILD N sha=" /tmp/perf_bench_$$.log | tail -1 | sed 's/.*sha=//')
SHA_U=$(grep "BUILD U sha=" /tmp/perf_bench_$$.log | tail -1 | sed 's/.*sha=//')
RECS_N=$(grep "BUILD N records=" /tmp/perf_bench_$$.log | tail -1 | sed 's/.*=//')
RECS_U=$(grep "BUILD U records=" /tmp/perf_bench_$$.log | tail -1 | sed 's/.*=//')

# Speedup math (avoid bc dep; use awk)
SPEEDUP_PCT=$(awk -v n="$ENUM_N_NS" -v u="$ENUM_U_NS" 'BEGIN{ if (u>0 && n>0) printf "%.2f", (n-u)*100.0/n; else print "TBD" }')

emit "STEP 5: Pull artifacts to claude"
RESULTS_DIR=/tmp/perf_bench_${LAUNCH_ID}_results
mkdir -p "$RESULTS_DIR"
for B in N U; do
    for f in solve.log merge.log; do
        $SCP "$ADMIN@$VM_IP:run_$B/$f" "$RESULTS_DIR/${B}_${f}" >/dev/null 2>&1 || true
    done
done

emit "STEP 6: Teardown"
teardown
rm -f /tmp/solve_ctl_${CONTROL_COMMIT}.c /tmp/solve_trt_${TREATMENT_COMMIT}.c

# ---------- emit JSON ----------
cat <<EOF

==== PERF_BENCH_RESULT ====
{
  "date_utc": "$(date -u +%FT%TZ)",
  "control_commit": "$CONTROL_COMMIT",
  "treatment_commit": "$TREATMENT_COMMIT",
  "treatment_pgo": $TREATMENT_PGO,
  "scale": "$SCALE",
  "node_limit": $NODE_LIMIT,
  "vm_size": "$VM_SIZE",
  "branch": "$BRANCH_PAIR $BRANCH_ORIENT",
  "threads": $THREADS,
  "page_cache_flushed": true,
  "control": {
    "enum_wall_ns": ${ENUM_N_NS:-null},
    "merge_wall_ns": ${MERGE_N_NS:-null},
    "sha": "${SHA_N:-TBD}",
    "records": ${RECS_N:-null}
  },
  "treatment": {
    "enum_wall_ns": ${ENUM_U_NS:-null},
    "merge_wall_ns": ${MERGE_U_NS:-null},
    "sha": "${SHA_U:-TBD}",
    "records": ${RECS_U:-null}
  },
  "speedup_enum_pct": "${SPEEDUP_PCT}",
  "sha_preserved": $([ "${SHA_N:-x}" = "${SHA_U:-y}" ] && echo true || echo false),
  "artifacts": "$RESULTS_DIR/"
}
==== /PERF_BENCH_RESULT ====

emit "DONE — copy the JSON block above into documentation/PERFORMANCE_HISTORY.md"
EOF
