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
#   4 = ERROR — THIS CHECK COULD NOT RUN. Not a verdict about capacity:
#       a malformed argument, or an `az` call that failed or returned
#       something unparseable. Treat it exactly as a HARD-FAIL for the
#       purposes of launching (do not launch), but escalate it as a
#       BROKEN PRECHECK rather than as an Azure capacity signal.
#       (Code 4 existed and was undocumented here until 2026-09-02 —
#       a caller written against this header's 0/2/3 would have fallen
#       through its own case statement on the one code that means
#       "nothing was measured".)
#
# MACHINE-READABLE VERDICT. Every exit path prints exactly one BARE line
#
#     SPOT_PRECHECK=OK | WAIT | HARD-FAIL | ERROR
#
# on stdout, with nothing before or after it on that line, so a caller can
# match it with `grep -qx 'SPOT_PRECHECK=OK'` — never by exit-code convention
# and never by reading the prose. Before 2026-09-02 the only two tokens this
# script emitted were `[precheck] SPOT_PRECHECK=ERROR need_vcpu ...` and
# `SPOT_PRECHECK=ERROR quota-unreadable`: one prefixed, both with trailing
# text, both on stderr, so `grep -qx` could not match either and the OK/WAIT/
# HARD-FAIL paths emitted no token at all. A verdict a matcher cannot read is
# not a verdict.
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
        echo "need_vcpu must be a plain integer, got: $NEED_VCPU" >&2
        echo "SPOT_PRECHECK=ERROR"
        exit 4 ;;
esac

PROBE_SKU="Standard_D2als_v7"
PROBE_NAME="spot-health-probe-$$"
PROBE_TIMEOUT_SEC=90
RG="${RG:-RG-CLAUDE}"

log() { echo "[$(date -u +%FT%TZ)] $*"; }

# The single exit point. The token is printed BARE and LAST so it is the line a
# `grep -qx` matcher reads; the reason goes through log(), which timestamps and
# indents and therefore can never be mistaken for the token.
verdict() {   # <OK|WAIT|HARD-FAIL|ERROR> <exit-code> [reason ...]
    local _v="$1" _rc="$2"; shift 2
    [ "$#" -gt 0 ] && log "  $*"
    echo "SPOT_PRECHECK=$_v"
    exit "$_rc"
}

log "=== Spot health pre-check: $TARGET_SKU in $REGION, need ${NEED_VCPU} vCPU ==="

# ===== Signal 1: SKU restrictions =====
log "Signal 1: Azure-published restrictions for $TARGET_SKU in $REGION"
# SIBLING OF THE CHARGED DEFECT, found sweeping (2026-09-02). Signal 2 was hardened to
# ERROR on an unreadable quota; signal 1 was left reading a DEAD `az` as good news. With a
# stub `az` that fails every call (the "not logged in" case, one `az account clear` away
# on any host), this printed "signal-1 OK: no published restrictions for
# Standard_D128als_v7" -- a positive attestation about Azure produced without reaching
# Azure. Today signal 2 catches the same broken `az` a few lines later, so the script still
# exits non-zero; that is luck, not design, and the OK line is false either way.
#
# THE EMPTY-ARRAY CASE IS ALSO NOT "UNRESTRICTED". `--query "[?name=='X'].restrictions"`
# returns `[]` when NO SKU ROW MATCHED -- the SKU is not offered in this region at all, or
# the name is misspelled -- which is the strongest possible reason not to launch, and it
# was folded in with `[[]]` (one row matched, empty restrictions = genuinely fine) into a
# single "OK". Three distinguishable states were being reported as one.
if ! RESTRICTIONS=$(az vm list-skus -l "$REGION" --query "[?name=='$TARGET_SKU'].restrictions" -o json 2>/dev/null); then
    verdict ERROR 4 "signal-1 ERROR: \`az vm list-skus\` failed (not logged in? az missing?). Nothing about $TARGET_SKU was measured."
fi
_R1=$(printf '%s' "$RESTRICTIONS" | tr -d '[:space:]')
case "$_R1" in
    '')
        verdict ERROR 4 "signal-1 ERROR: \`az vm list-skus\` returned NOTHING. An empty answer is not 'no restrictions' -- it is a check that did not run." ;;
    '[]')
        log "  signal-1 HARD-FAIL: no SKU named $TARGET_SKU is offered in $REGION"
        log "  (an empty result set means the SKU/region pair does not exist, or the SKU"
        log "   name is wrong -- either way there is nothing to launch here)"
        verdict HARD-FAIL 3 ;;
    '[[]]')
        log "  signal-1 OK: $TARGET_SKU is offered in $REGION with no published restrictions" ;;
    *)
        # Check if any restriction is region-scoped to our region
        BLOCKED=$(printf '%s' "$RESTRICTIONS" | grep -ic "$REGION" || true)
        if [ "${BLOCKED:-0}" -gt 0 ]; then
            log "  signal-1 HARD-FAIL: $TARGET_SKU restricted in $REGION"
            log "  restrictions: $RESTRICTIONS"
            verdict HARD-FAIL 3
        fi
        log "  signal-1 OK: restrictions present but not in $REGION" ;;
esac

# ===== Signal 2: family vCPU quota headroom =====
# Dalsv7 family is the shared bucket; if it's near-full we'll get
# AllocationFailed even if the SKU shows no restriction.
log "Signal 2: family vCPU quota headroom in $REGION"
if ! USAGE_JSON=$(az vm list-usage -l "$REGION" --query "[?contains(name.value, 'Dalsv7')]|[0]" -o json 2>/dev/null); then
    verdict ERROR 4 "signal-2 ERROR: \`az vm list-usage\` failed; family quota was not measured."
fi
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
    verdict ERROR 4 "refusing to report headroom this check did not measure"
fi
FREE=$((LIMIT - USED))
log "  family Dalsv7: $USED / $LIMIT used; $FREE free"
if [ "$FREE" -lt "$NEED_VCPU" ]; then
    log "  signal-2 WAIT: need $NEED_VCPU vCPU but only $FREE free in family"
    log "  (a deallocated VM still counts; delete or shrink one to free quota)"
    verdict WAIT 2
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
    --no-wait > /dev/null 2>&1 || \
    verdict HARD-FAIL 3 "signal-3 HARD-FAIL: \`az vm create\` was REJECTED outright (not a capacity decline -- a bad SKU, RG, vnet/subnet/NSG name, or missing ssh key). The probe never existed, so the polling loop below would have timed out and reported WAIT, i.e. 'transient capacity', for a configuration error."

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
        verdict WAIT 2
    fi
done

if [ "$PROBE_OK" -eq 0 ]; then
    log "  signal-3 WAIT: probe did not reach 'VM running' within ${PROBE_TIMEOUT_SEC}s"
    verdict WAIT 2
fi

# Probe survived initial provisioning; quickly check it's still running
# (catches the immediate-evict-after-allocation case)
sleep 15
FINAL_POW=$(az vm show -g "$RG" -n "$PROBE_NAME" --query 'instanceView.statuses[?starts_with(code, `PowerState`)].displayStatus | [0]' -d -o tsv 2>/dev/null)
if [ "$FINAL_POW" != "VM running" ]; then
    log "  signal-3 WAIT: probe evicted within 15s of provisioning (Spot capacity unstable)"
    verdict WAIT 2
fi
log "  signal-3 OK: probe ran for 15s without eviction"

# ===== Verdict =====
log "=== VERDICT: OK — safe to launch $TARGET_SKU Spot in $REGION ==="
verdict OK 0
