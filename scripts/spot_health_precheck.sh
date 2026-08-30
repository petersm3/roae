#!/usr/bin/env bash
# Spot health pre-check for Azure Dalsv7 family.
#
# Answers: "is it currently safe to launch a Spot VM of <sku> in
# <region>?" via three escalating signals:
#   1. Azure-published SKU restrictions (cheap; az vm list-skus)
#   2. Family vCPU quota headroom (cheap; az vm list-usage)
#   3. Empirical probe — launch a $0.01 D2als_v7 Spot, see if it
#      provisions within 90s and doesn't immediately evict (definitive
#      but costs ~$0.01 per probe)
#
# Exit codes:
#   0 = OK to launch
#   2 = WAIT (transient capacity issue; caller retries per time-window
#       policy — see memory `feedback_spot_relaunch_time_window`)
#   3 = HARD-FAIL (region restricted, quota exhausted, or probe error
#       suggesting persistent issue — operator escalation needed)
#
# Usage:
#   spot_health_precheck.sh [region] [target_sku] [need_vcpu]
#
# Args:
#   region      e.g. westus3 (default)
#   target_sku  e.g. Standard_D128als_v7 (default)
#   need_vcpu   vCPUs the target campaign needs (default: 128)
#
# Stdout: one line per signal checked + final OK/WAIT/HARD-FAIL verdict.
# Stderr: errors and probe output.

set -uo pipefail

REGION="${1:-westus3}"
TARGET_SKU="${2:-Standard_D128als_v7}"
NEED_VCPU="${3:-128}"

# Codex v2 / fail-open class: `[ "$FREE" -lt "$NEED_VCPU" ]` ERRORS when NEED_VCPU is
# not an integer ("integer expression expected"), and bash treats a failed test as
# FALSE -- so the script fell through to "signal-2 OK" and printed a green light
# having checked nothing, immediately before a real `az vm create`. Measured with
# NEED_VCPU=128vCPU. Validate the input instead of trusting the caller.
case "$NEED_VCPU" in
    ''|*[!0-9]*)
        echo "[precheck] SPOT_PRECHECK=ERROR need_vcpu must be a plain integer, got: $NEED_VCPU" >&2
        exit 4 ;;
esac

PROBE_SKU="Standard_D2als_v7"
PROBE_NAME="spot-health-probe-$$"
PROBE_TIMEOUT_SEC=90
RG="${RG:-RG-CLAUDE}"

log() { echo "[$(date -u +%FT%TZ)] $*"; }

log "=== Spot health pre-check: $TARGET_SKU in $REGION, need ${NEED_VCPU} vCPU ==="

# ===== Signal 1: SKU restrictions =====
log "Signal 1: Azure-published restrictions for $TARGET_SKU in $REGION"
RESTRICTIONS=$(az vm list-skus -l "$REGION" --query "[?name=='$TARGET_SKU'].restrictions" -o json 2>/dev/null)
if [ -z "$RESTRICTIONS" ] || [ "$RESTRICTIONS" = "[[]]" ] || [ "$RESTRICTIONS" = "[]" ]; then
    log "  signal-1 OK: no published restrictions for $TARGET_SKU"
else
    # Check if any restriction is region-scoped to our region
    BLOCKED=$(echo "$RESTRICTIONS" | grep -ic "$REGION" || true)
    if [ "$BLOCKED" -gt 0 ]; then
        log "  signal-1 HARD-FAIL: $TARGET_SKU restricted in $REGION"
        log "  restrictions: $RESTRICTIONS"
        exit 3
    fi
    log "  signal-1 OK: restrictions present but not in $REGION"
fi

# ===== Signal 2: family vCPU quota headroom =====
# Dalsv7 family is the shared bucket; if it's near-full we'll get
# AllocationFailed even if the SKU shows no restriction.
log "Signal 2: family vCPU quota headroom in $REGION"
USAGE_JSON=$(az vm list-usage -l "$REGION" --query "[?contains(name.value, 'Dalsv7')]|[0]" -o json 2>/dev/null)
# az now emits these as QUOTED STRINGS ("currentValue": "8"), not bare numbers. The
# original pattern required an unquoted digit and so matched NOTHING -- which became
# FREE=0 and printed "only 0 free", a false WAIT that would block every launch while
# 122 vCPU were actually free. Accept both forms. (Same class as the known az
# silent-wrong-answer traps: -o tsv rendering null as "None", diskSizeGB vs diskSizeGb.)
USED=$(echo "$USAGE_JSON" | grep -oP '"currentValue":\s*"?\K[0-9]+' | head -1)
LIMIT=$(echo "$USAGE_JSON" | grep -oP '"limit":\s*"?\K[0-9]+' | head -1)
# An unreadable quota is NOT "0 free". Both arms of the old arithmetic silently
# treated a failed `az` call as zero, which happened to fail closed here -- but it
# reported "0 / 0 used" as though measured. A check that cannot see its target must
# ERROR, not report a number it did not obtain.
case "${USED:-}" in ''|*[!0-9]*) USED=""; esac
case "${LIMIT:-}" in ''|*[!0-9]*) LIMIT=""; esac
if [ -z "$USED" ] || [ -z "$LIMIT" ]; then
    log "  signal-2 ERROR: could not read Dalsv7 quota from az (empty or unparseable)"
    log "  refusing to report headroom this check did not measure"
    echo "SPOT_PRECHECK=ERROR quota-unreadable" >&2
    exit 4
fi
FREE=$((LIMIT - USED))
log "  family Dalsv7: $USED / $LIMIT used; $FREE free"
if [ "$FREE" -lt "$NEED_VCPU" ]; then
    log "  signal-2 WAIT: need $NEED_VCPU vCPU but only $FREE free in family"
    log "  (a deallocated VM still counts; delete or shrink one to free quota)"
    exit 2
fi
log "  signal-2 OK: $FREE vCPU free, enough for $NEED_VCPU"

# ===== Signal 3: empirical probe (D2als_v7 Spot, ~$0.01) =====
log "Signal 3: empirical probe — provisioning $PROBE_SKU Spot for ${PROBE_TIMEOUT_SEC}s timeout"

# Cleanup on exit
cleanup_probe() {
    az vm delete -g "$RG" -n "$PROBE_NAME" --yes --no-wait 2>/dev/null || true
    # also remove any orphan NIC/IP/disk if they were created
    az network nic delete -g "$RG" -n "${PROBE_NAME}VMNic" --no-wait 2>/dev/null || true
}
trap cleanup_probe EXIT

PROBE_START=$(date +%s)
az vm create \
    --resource-group "$RG" \
    --name "$PROBE_NAME" \
    --location "$REGION" \
    --size "$PROBE_SKU" \
    --priority Spot \
    --eviction-policy Delete \
    --max-price -1 \
    --image Ubuntu2404 \
    --admin-username solver \
    --ssh-key-values "$HOME/.ssh/id_rsa.pub" \
    --vnet-name "claude-vnet-${REGION}" \
    --subnet default \
    --nsg "claudeNSG-${REGION}" \
    --public-ip-address "" \
    --os-disk-size-gb 32 \
    --tags purpose=spot_health_probe \
    --no-wait > /dev/null 2>&1

# Poll for the VM to reach "VM running" within the timeout
PROBE_OK=0
while [ $(($(date +%s) - PROBE_START)) -lt "$PROBE_TIMEOUT_SEC" ]; do
    sleep 10
    POW=$(az vm show -g "$RG" -n "$PROBE_NAME" --query 'instanceView.statuses[?starts_with(code, `PowerState`)].displayStatus | [0]' -d -o tsv 2>/dev/null)
    PROV=$(az vm show -g "$RG" -n "$PROBE_NAME" --query 'provisioningState' -o tsv 2>/dev/null)
    log "  probe poll: prov=$PROV pow=$POW"
    if [ "$PROV" = "Succeeded" ] && [ "$POW" = "VM running" ]; then
        PROBE_OK=1
        break
    fi
    if [ "$PROV" = "Failed" ]; then
        log "  signal-3 WAIT: probe provisioning FAILED (Azure declined Spot allocation)"
        exit 2
    fi
done

if [ "$PROBE_OK" -eq 0 ]; then
    log "  signal-3 WAIT: probe did not reach 'VM running' within ${PROBE_TIMEOUT_SEC}s"
    exit 2
fi

# Probe survived initial provisioning; quickly check it's still running
# (catches the immediate-evict-after-allocation case)
sleep 15
FINAL_POW=$(az vm show -g "$RG" -n "$PROBE_NAME" --query 'instanceView.statuses[?starts_with(code, `PowerState`)].displayStatus | [0]' -d -o tsv 2>/dev/null)
if [ "$FINAL_POW" != "VM running" ]; then
    log "  signal-3 WAIT: probe evicted within 15s of provisioning (Spot capacity unstable)"
    exit 2
fi
log "  signal-3 OK: probe ran for 15s without eviction"

# ===== Verdict =====
log "=== VERDICT: OK — safe to launch $TARGET_SKU Spot in $REGION ==="
exit 0
