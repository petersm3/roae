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
#   - PREFLIGHT THROTTLE PROBE (added 2026-09-02; mandatory per the 2026-05-18
#     finding in PERFORMANCE_HISTORY.md — workload-time MHz cannot distinguish
#     a throttled host from memory-bound saturation, so the ONLY throttle
#     signal is a pure-CPU burn BEFORE the bench): `yes > /dev/null` on every
#     core for --burn-seconds (default 60, floor 30), then per-core MHz is
#     sampled at the end of the burn. The minimum must be >= --throttle-min-mhz
#     (default 3664, the AVX-512 definitive-bench precedent for D128als_v7).
#     Reported as HEALTHY / THROTTLED / UNVERIFIED on its own token line; a
#     THROTTLED or UNVERIFIED host is torn down BEFORE any bench runs (exit 5),
#     because a bench without throttle evidence cannot enter the record either
#     way and would only spend the VM.
#   - Page-cache flushed (`echo 3 > /proc/sys/vm/drop_caches`) between paired
#     runs, and the flush is VERIFIED, not assumed: each run reports
#     CONFIRMED / FAILED / UNVERIFIED and the script refuses to certify a
#     bench whose flush was not CONFIRMED for both builds.
#   - Enum-only wall time captured around the `--branch` command, BEFORE
#     `--merge`. Merge wall is captured separately as a correctness-gate cost,
#     not a perf metric.
#   - `sha` and `records` are LOGICAL (added 2026-09-02): solutions.bin is
#     gz-framed by default (SOLUTIONS_FORMAT.md "On-disk framing"), so the
#     gzip magic is sniffed and the hash and byte count are taken over the
#     DECOMPRESSED stream — `gzip -dc solutions.bin | sha256sum`, the
#     convention every anchor in CANONICAL_HASHES.md uses. The previous
#     `sha256sum solutions.bin` hashed the compressed CONTAINER, which varies
#     with zlib version and level and false-mismatches a byte-identical
#     artifact (phantom drift), and `(container_bytes-32)/32` was a fictional
#     record count. The container sha is still reported, labelled as such.
#   - Multi-scale: 1B-node smoke + 1T-node full bench by default.
#   - Output: JSON line to stdout that drops into a PERFORMANCE_HISTORY.md entry.
#
# Usage:
#   perf_bench.sh --control-commit <sha> --treatment-commit <sha> [--treatment-pgo]
#                 [--scale 1B|1T|11.2T] [--branch <p> <o>] [--threads N]
#                 [--pgo-workload "<cmd>"] [--keep-vm]
#                 [--throttle-min-mhz N] [--burn-seconds N]
#
# Exit codes:
#   0  bench completed AND methodology confirmed (emits PERF_BENCH_METHODOLOGY=OK)
#   2  bad arguments
#   1  VM never reachable
#   3  bench ran but the page-cache flush was NOT confirmed for both builds —
#      the JSON is emitted with "methodology_valid": false and must NOT be
#      pasted into PERFORMANCE_HISTORY.md (emits PERF_BENCH_METHODOLOGY=VIOLATED)
#   4  build or --selftest failed on the VM; no bench produced
#   5  preflight throttle probe did not read HEALTHY (THROTTLED, or UNVERIFIED
#      because MHz could not be sampled / the burn was too short / no token
#      came back) — VM torn down, no bench produced, PERF_BENCH_METHODOLOGY=VIOLATED.
#      Per feedback_throttle_probe_eviction_recovery: deallocate and retry on
#      another host.
#
# Gate on it with:  perf_bench.sh ... | grep -qx PERF_BENCH_METHODOLOGY=OK
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
THROTTLE_MIN_MHZ=3664   # AVX-512 definitive-bench precedent (PERFORMANCE_HISTORY.md, D128als_v7)
BURN_SECS=60            # sample is taken at the END of the burn; the 2026-05-18 finding needs >=30 s
BURN_FLOOR=30

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
        --throttle-min-mhz) THROTTLE_MIN_MHZ="$2"; shift 2 ;;
        --burn-seconds) BURN_SECS="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 2 ;;
    esac
done

[ -z "$CONTROL_COMMIT" ]   && { echo "Required: --control-commit <sha>"; exit 2; }
[ -z "$TREATMENT_COMMIT" ] && { echo "Required: --treatment-commit <sha>"; exit 2; }
case "$THROTTLE_MIN_MHZ" in ''|*[!0-9]*) echo "--throttle-min-mhz must be an integer MHz"; exit 2 ;; esac
case "$BURN_SECS" in ''|*[!0-9]*) echo "--burn-seconds must be an integer"; exit 2 ;; esac
# A burn shorter than the floor is accepted so a harness can exercise the path, but the probe it
# yields is UNVERIFIED by construction (below), never HEALTHY: there is no flag that turns the
# throttle evidence off.

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
# Per-step raw transcripts. These are the ONLY parse source for the result
# fields below: they are written synchronously by `tee`, un-indented, so a
# whole-line `grep -qx` on a verdict token means what it says. (The previous
# version grepped /tmp/perf_bench_$$.log, which is written asynchronously by
# the process-substitution `tee` on line 29 and is indented by `sed`.)
# Keyed on $$ as well as the minute: two launches in the same minute used to share this
# directory, and the token parsers below read whatever transcript is there — a stale
# probe.out from an earlier run would have supplied this run's verdict.
RAW_DIR=/tmp/perf_bench_${LAUNCH_ID}_$$_raw
rm -rf "$RAW_DIR"; mkdir -p "$RAW_DIR"

$SSH "$ADMIN@$VM_IP" 'sudo apt-get update -qq && sudo apt-get install -y -qq build-essential zlib1g-dev' 2>&1 | tail -1 | sed 's/^/  /'

git -C "$REPO" show "${CONTROL_COMMIT}:solve.c"   > /tmp/solve_ctl_${CONTROL_COMMIT}.c
git -C "$REPO" show "${TREATMENT_COMMIT}:solve.c" > /tmp/solve_trt_${TREATMENT_COMMIT}.c
$SCP /tmp/solve_ctl_${CONTROL_COMMIT}.c   "$ADMIN@$VM_IP:solve_ctl.c" >/dev/null
$SCP /tmp/solve_trt_${TREATMENT_COMMIT}.c "$ADMIN@$VM_IP:solve_trt.c" >/dev/null

$SSH "$ADMIN@$VM_IP" "
    set -e
    # pipefail is REQUIRED, not cosmetic: every build/selftest line below ends
    # in \`| tail -N\`, and without pipefail the pipeline status is tail's (always
    # 0). A failing \`--selftest\` would be reported as a clean build.
    set -o pipefail
    # Build N (control)
    gcc -O3 -flto -pthread -fopenmp -march=native -DGIT_HASH=\\\"${CONTROL_COMMIT}\\\" -o solve_N solve_ctl.c -lm -lz 2>&1 | tail -2
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
            -DGIT_HASH=\\\"${TREATMENT_COMMIT}\\\" -o solve_U solve_trt.c -lm -lz 2>&1 | tail -2
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
            -DGIT_HASH=\\\"${TREATMENT_COMMIT}\\\" -o solve_U solve_trt.c -lm -lz 2>&1 | tail -3
    else
        gcc -O3 -flto -pthread -fopenmp -march=native -DGIT_HASH=\\\"${TREATMENT_COMMIT}\\\" -o solve_U solve_trt.c -lm -lz 2>&1 | tail -2
    fi
    sha256sum solve_U
    ./solve_U --selftest 2>&1 | tail -2
" 2>&1 | tee "$RAW_DIR/build.out" | sed 's/^/  /'
# `set -uo pipefail` is in force, so this pipeline's status is ssh's. A failed
# build must NOT fall through to a bench that then reports timings for
# whichever binary happens to exist.
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    emit "🔴 FATAL: build/selftest failed on the VM (see $RAW_DIR/build.out) — no bench produced"
    teardown
    printf '\nPERF_BENCH_METHODOLOGY=VIOLATED\n'
    exit 4
fi

# ---------- preflight throttle probe ----------
# Pure-CPU burn on every core, MHz sampled at the END of the burn. Three outcomes, each on its
# own token line, and no fourth that means "assume healthy":
#   HEALTHY    - min per-core MHz >= THROTTLE_MIN_MHZ after a burn of at least BURN_FLOOR s
#   THROTTLED  - sampled and below the threshold
#   UNVERIFIED - could not be sampled (no nproc / no MHz source), or the burn was shorter than
#                the floor, or no token came back at all. NOT a pass.
emit "STEP 2b: Preflight throttle probe (${BURN_SECS}s pure-CPU burn on every core; min MHz must be >= ${THROTTLE_MIN_MHZ}; floor ${BURN_FLOOR}s)"
$SSH "$ADMIN@$VM_IP" "
    set +e
    PROBE=UNVERIFIED; PROBE_DETAIL=no-detail
    NC=\$(nproc 2>/dev/null); case \"\$NC\" in ''|*[!0-9]*) NC=0;; esac
    if [ \"\$NC\" -lt 1 ]; then
        PROBE_DETAIL=nproc-unreadable
    else
        for i in \$(seq 1 \"\$NC\"); do yes > /dev/null & done
        sleep $BURN_SECS
        MHZ=\$(awk '/^cpu MHz/{print \$4}' /proc/cpuinfo 2>/dev/null)
        if [ -z \"\$MHZ\" ]; then
            MHZ=\$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | awk '{printf \"%.0f\\n\", \$1/1000}')
        fi
        kill \$(jobs -p) 2>/dev/null; wait 2>/dev/null
        if [ -z \"\$MHZ\" ]; then
            PROBE_DETAIL=cpu-mhz-unreadable
        else
            STATS=\$(printf '%s\\n' \"\$MHZ\" | awk 'NR==1{mn=\$1;mx=\$1} {s+=\$1; n++; if(\$1<mn)mn=\$1; if(\$1>mx)mx=\$1} END{printf \"%d %d %d %d\", mn, s/n, mx, n}')
            set -- \$STATS
            PROBE_DETAIL=min_\${1}_avg_\${2}_max_\${3}_mhz_over_\${4}_samples_\${NC}_cores_burn_${BURN_SECS}s_threshold_${THROTTLE_MIN_MHZ}
            if [ $BURN_SECS -lt $BURN_FLOOR ]; then
                PROBE=UNVERIFIED; PROBE_DETAIL=burn-too-short-\${PROBE_DETAIL}
            elif [ \"\$1\" -ge $THROTTLE_MIN_MHZ ]; then PROBE=HEALTHY
            else PROBE=THROTTLED; fi
        fi
    fi
    printf '\\n'
    echo \"PERFBENCH_THROTTLE_PROBE=\$PROBE\"
    echo \"PERFBENCH_THROTTLE_DETAIL=\$PROBE_DETAIL\"
" 2>&1 | tee "$RAW_DIR/probe.out" | sed 's/^/  /'

probe_status() {   # exactly three accepted tokens; absence of all three reads UNVERIFIED
    local raw="$RAW_DIR/probe.out" st
    for st in HEALTHY THROTTLED UNVERIFIED; do
        if [ -f "$raw" ] && grep -qx "PERFBENCH_THROTTLE_PROBE=${st}" "$raw"; then printf '%s' "$st"; return; fi
    done
    printf 'UNVERIFIED'
}
THROTTLE_PROBE=$(probe_status)
THROTTLE_DETAIL=$( { [ -f "$RAW_DIR/probe.out" ] && sed -n 's/^PERFBENCH_THROTTLE_DETAIL=//p' "$RAW_DIR/probe.out" | tail -1; } )
THROTTLE_DETAIL=${THROTTLE_DETAIL:-no-verdict-token-in-transcript}
emit "  throttle_probe=$THROTTLE_PROBE ($THROTTLE_DETAIL)"
if [ "$THROTTLE_PROBE" != HEALTHY ]; then
    emit "🔴 FATAL: preflight throttle probe is $THROTTLE_PROBE, not HEALTHY — no bench will be run on this host"
    emit "🔴   $THROTTLE_DETAIL"
    emit "🔴   Deallocate and retry on another host (feedback_throttle_probe_eviction_recovery)."
    teardown
    printf '\nPERF_BENCH_METHODOLOGY=VIOLATED\n'
    exit 5
fi

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
        # --- page-cache flush: ATTEMPT, then REPORT WHAT WAS OBSERVED ---
        # Three outcomes, all reported explicitly on their own line:
        #   CONFIRMED  - the kernel accepted the drop_caches write
        #   FAILED     - the write was attempted and rejected
        #   UNVERIFIED - the flush could not even be attempted (no sudo, no
        #                interface, no /proc/meminfo). NOT a pass.
        # There is deliberately no fourth outcome that means \"assume it worked\".
        PCF=UNVERIFIED
        PCF_DETAIL=no-detail
        CB=\$(awk '/^Cached:/{print \$2; exit}' /proc/meminfo 2>/dev/null)
        if [ -z \"\$CB\" ]; then
            PCF=UNVERIFIED; PCF_DETAIL=proc-meminfo-unreadable
        elif [ ! -e /proc/sys/vm/drop_caches ]; then
            PCF=UNVERIFIED; PCF_DETAIL=no-drop_caches-interface
        elif ! sudo -n true 2>/dev/null; then
            PCF=UNVERIFIED; PCF_DETAIL=no-passwordless-sudo
        elif ! echo 3 | sudo -n tee /proc/sys/vm/drop_caches >/dev/null 2>&1; then
            PCF=FAILED; PCF_DETAIL=drop_caches-write-rejected
        else
            CA=\$(awk '/^Cached:/{print \$2; exit}' /proc/meminfo 2>/dev/null)
            if [ -z \"\$CA\" ]; then
                PCF=UNVERIFIED; PCF_DETAIL=proc-meminfo-unreadable-after-write
            else
                PCF=CONFIRMED; PCF_DETAIL=cached_kB_\${CB}_to_\${CA}
            fi
        fi
        # Leading newline so the token owns its line: a verdict token that lands
        # glued to prior output is invisible to the \`grep -qx\` that reads it.
        printf '\\n'
        echo \"PERFBENCH_PAGE_CACHE_FLUSHED_$BUILD=\$PCF\"
        echo \"PERFBENCH_PAGE_CACHE_DETAIL_$BUILD=\$PCF_DETAIL\"
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
            # LOGICAL sha + record count (SOLUTIONS_FORMAT.md \"On-disk framing\"): sniff the
            # gzip magic 1f 8b; a gz-framed file is hashed and sized over its DECOMPRESSED
            # stream, the convention of every anchor in CANONICAL_HASHES.md. The container
            # sha is reported too, labelled, so a reader can never mistake one for the other.
            if [ -s solutions.bin ]; then
                CSHA=\$(sha256sum solutions.bin | awk '{print \$1}')
                if [ \"\$(head -c 2 solutions.bin | od -An -tx1 | tr -d ' \\n')\" = 1f8b ]; then
                    FRAMING=gzip
                    LSHA=\$(gzip -dc solutions.bin | sha256sum | awk '{print \$1}'); R1=\${PIPESTATUS[0]}
                    LBYTES=\$(gzip -dc solutions.bin | wc -c); R2=\${PIPESTATUS[0]}
                    if [ \"\$R1\" -ne 0 ] || [ \"\$R2\" -ne 0 ]; then LSHA=DECOMPRESS-FAILED; LBYTES=; fi
                else
                    FRAMING=raw
                    LSHA=\$CSHA
                    LBYTES=\$(stat -c %s solutions.bin)
                fi
                echo \"BUILD $BUILD framing=\$FRAMING\"
                echo \"BUILD $BUILD sha=\$LSHA\"
                echo \"BUILD $BUILD container_sha=\$CSHA\"
                if [ -n \"\$LBYTES\" ] && [ \"\$LBYTES\" -ge 32 ]; then
                    echo \"BUILD $BUILD logical_bytes=\$LBYTES\"
                    echo \"BUILD $BUILD records=\$(( (LBYTES - 32) / 32 ))\"
                else
                    echo \"BUILD $BUILD logical_bytes=null\"
                    echo \"BUILD $BUILD records=null\"
                fi
            else
                echo \"BUILD $BUILD framing=absent\"
                echo \"BUILD $BUILD sha=ABSENT\"
            fi
        fi
    "
}

run_enum_only N 2>&1 | tee "$RAW_DIR/N.out" | sed 's/^/  /'
run_enum_only U 2>&1 | tee "$RAW_DIR/U.out" | sed 's/^/  /'

# ---------- collect ----------
emit "STEP 4: Collect results + emit JSON"

# Field extraction, from the raw per-build transcript only.
bench_field() {  # $1 = build label, $2 = key
    local raw="$RAW_DIR/$1.out"
    [ -f "$raw" ] || return 0
    sed -n "s/^BUILD $1 $2=//p" "$raw" | tail -1
}

# Page-cache-flush verdict. There are exactly three accepted tokens and the
# absence of all three is NOT a pass — an unreachable/aborted run leaves no
# token, and that reads as UNVERIFIED, which fails the methodology gate.
pcf_status() {  # $1 = build label
    local b=$1 raw="$RAW_DIR/$1.out" st
    for st in CONFIRMED FAILED UNVERIFIED; do
        if [ -f "$raw" ] && grep -qx "PERFBENCH_PAGE_CACHE_FLUSHED_${b}=${st}" "$raw"; then
            printf '%s' "$st"; return
        fi
    done
    printf 'UNVERIFIED'
}
pcf_detail() {  # $1 = build label
    local b=$1 raw="$RAW_DIR/$1.out" d=""
    [ -f "$raw" ] && d=$(sed -n "s/^PERFBENCH_PAGE_CACHE_DETAIL_${b}=//p" "$raw" | tail -1)
    printf '%s' "${d:-no-verdict-token-in-transcript}"
}

ENUM_N_NS=$(bench_field N enum_wall_ns)
ENUM_U_NS=$(bench_field U enum_wall_ns)
MERGE_N_NS=$(bench_field N merge_wall_ns)
MERGE_U_NS=$(bench_field U merge_wall_ns)
SHA_N=$(bench_field N sha)
SHA_U=$(bench_field U sha)
RECS_N=$(bench_field N records)
RECS_U=$(bench_field U records)
FRAMING_N=$(bench_field N framing)
FRAMING_U=$(bench_field U framing)
CSHA_N=$(bench_field N container_sha)
CSHA_U=$(bench_field U container_sha)

PCF_N=$(pcf_status N);  PCF_DETAIL_N=$(pcf_detail N)
PCF_U=$(pcf_status U);  PCF_DETAIL_U=$(pcf_detail U)

# Verifier closure: the probe gate above exits 5 on anything but HEALTHY, so this branch is
# unreachable today — it is here so that if that exit is ever removed or bypassed, the JSON
# still cannot say methodology_valid without throttle evidence.
if [ "$PCF_N" = CONFIRMED ] && [ "$PCF_U" = CONFIRMED ] && [ "$THROTTLE_PROBE" = HEALTHY ]; then
    PAGE_CACHE_FLUSHED="CONFIRMED"
    METHODOLOGY_OK=1
elif [ "$THROTTLE_PROBE" != HEALTHY ]; then
    PAGE_CACHE_FLUSHED="control=$PCF_N, treatment=$PCF_U"
    METHODOLOGY_OK=0
    emit "🔴🔴🔴 METHODOLOGY VIOLATION — throttle probe is $THROTTLE_PROBE ($THROTTLE_DETAIL)"
else
    PAGE_CACHE_FLUSHED="NOT CONFIRMED (control=$PCF_N [$PCF_DETAIL_N], treatment=$PCF_U [$PCF_DETAIL_U])"
    METHODOLOGY_OK=0
    emit "🔴🔴🔴 METHODOLOGY VIOLATION — page-cache flush NOT confirmed"
    emit "🔴   control:   $PCF_N ($PCF_DETAIL_N)"
    emit "🔴   treatment: $PCF_U ($PCF_DETAIL_U)"
    emit "🔴 The paired runs were NOT cache-isolated from each other. The"
    emit "🔴 speedup below is NOT a valid perf measurement and must NOT be"
    emit "🔴 pasted into PERFORMANCE_HISTORY.md. Re-run on a host with"
    emit "🔴 passwordless sudo, or record the entry as methodology-invalid."
fi

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
  "page_cache_flushed": "$PAGE_CACHE_FLUSHED",
  "throttle_probe": "$THROTTLE_PROBE",
  "throttle_probe_detail": "$THROTTLE_DETAIL",
  "methodology_valid": $([ "$METHODOLOGY_OK" -eq 1 ] && echo true || echo false),
  "sha_scope": "logical (decompressed stream; gzip -dc solutions.bin | sha256sum when gz-framed) — the CANONICAL_HASHES.md convention; container_sha is the on-disk file and is NOT comparable to any anchor",
  "control": {
    "enum_wall_ns": ${ENUM_N_NS:-null},
    "merge_wall_ns": ${MERGE_N_NS:-null},
    "sha": "${SHA_N:-TBD}",
    "container_sha": "${CSHA_N:-TBD}",
    "framing": "${FRAMING_N:-unknown}",
    "records": ${RECS_N:-null},
    "page_cache_flush": "$PCF_N",
    "page_cache_flush_detail": "$PCF_DETAIL_N"
  },
  "treatment": {
    "enum_wall_ns": ${ENUM_U_NS:-null},
    "merge_wall_ns": ${MERGE_U_NS:-null},
    "sha": "${SHA_U:-TBD}",
    "container_sha": "${CSHA_U:-TBD}",
    "framing": "${FRAMING_U:-unknown}",
    "records": ${RECS_U:-null},
    "page_cache_flush": "$PCF_U",
    "page_cache_flush_detail": "$PCF_DETAIL_U"
  },
  "speedup_enum_pct": "${SPEEDUP_PCT}",
  "sha_preserved": $([ -n "${SHA_N:-}" ] && [ "${SHA_N}" = "${SHA_U:-}" ] && [ "${SHA_N}" != ABSENT ] && [ "${SHA_N}" != DECOMPRESS-FAILED ] && echo true || echo false),
  "artifacts": "$RESULTS_DIR/",
  "raw_transcripts": "$RAW_DIR/"
}
==== /PERF_BENCH_RESULT ====
EOF

# The `emit "DONE ..."` line used to sit INSIDE the heredoc above, so it was
# printed as literal text and never executed.
emit "DONE — raw transcripts in $RAW_DIR/"

# Machine-readable verdict, on its own line, for a caller to gate on with
#   scripts/perf_bench.sh ... | grep -qx PERF_BENCH_METHODOLOGY=OK
if [ "$METHODOLOGY_OK" -eq 1 ]; then
    printf '\nPERF_BENCH_METHODOLOGY=OK\n'
    emit "Copy the JSON block above into documentation/PERFORMANCE_HISTORY.md"
    exit 0
else
    printf '\nPERF_BENCH_METHODOLOGY=VIOLATED\n'
    emit "🔴 DO NOT paste this entry into PERFORMANCE_HISTORY.md — see the banner above"
    exit 3
fi
