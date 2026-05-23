#!/usr/bin/env bash
# spot_pre_launch_check.sh — pre-launch eviction-risk guard for Spot VMs.
#
# Purpose:
#   For canonical campaigns (≥1h wall on Spot), check the current launch
#   window against time-of-week heuristics for Azure Spot eviction risk.
#   Catches "launching at Tuesday 10 AM PT" mistakes that maximize the
#   probability of eviction during the costly fast-skip / load phase.
#
# Background:
#   Empirically, Azure Spot eviction rates in US west regions correlate with
#   US business-hours demand on the underlying on-demand SKU pool. Launching
#   into peak demand means a higher chance of eviction within the first few
#   hours — which is the worst outcome for a canonical run, because the
#   fast-skip phase at resume time on a recovery VM takes ~3-4h to catch up
#   to the prior progress (see x/roae/FAST_SKIP_RESUME_PHASE_ANALYSIS_2026_05_22.md).
#
# Risk windows (heuristic, based on prior project experience + standard
# cloud-ops patterns; refine over time via accumulated eviction log):
#   HIGH    Mon-Fri 09:00-16:00 PT     US business-hours peak
#   HIGH    Mon morning 05:00-11:00 PT spike risk (deferred Friday work resuming)
#   MEDIUM  Mon-Fri 05:00-09:00 PT     workday ramp-up
#   MEDIUM  Mon-Fri 16:00-20:00 PT     business hours tail
#   LOW     all other times            evenings + overnight + weekends
#
# Exit codes:
#   0   LOW risk — OK to launch
#   1   MEDIUM risk — caller should consider deferring or proceed with awareness
#   2   HIGH risk — caller should defer 6-12h or use --force flag
#   3   force-override (HIGH risk but caller passed --force)
#
# Usage:
#   ./spot_pre_launch_check.sh                    # check current time
#   ./spot_pre_launch_check.sh --force            # override HIGH-risk block
#   ./spot_pre_launch_check.sh --sku D128als_v7 --region westus3   # context-aware advice
#
# Integration:
#   Canonical-campaign launch scripts should call this BEFORE provisioning
#   any Spot VM expected to run >1h:
#
#     scripts/spot_pre_launch_check.sh || {
#       echo "Spot pre-launch check failed; refusing to launch."
#       exit 1
#     }
#
# Spot Advisor portal URL (manual cross-check — Spot Advisor data is not
# exposed via Azure CLI; portal-only):
#   https://portal.azure.com/#blade/Microsoft_Azure_ComputeIaaS/SpotVmEvictionRatePricingBlade
#
# See also:
#   - x/roae/FAST_SKIP_RESUME_PHASE_ANALYSIS_2026_05_22.md (why eviction-timing matters)
#   - documentation/DEVELOPMENT.md §Monitor/orchestrator (ps pcpu interpretation)

set -uo pipefail

FORCE=0
SKU=""
REGION=""
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --sku) SKU="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help)
      sed -n '2,/^set -/p' "$0" | head -n -2
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

log() { [[ $QUIET -eq 0 ]] && echo "[spot-pre-launch] $*"; }

# Get current Pacific time (handles PDT/PST automatically via TZ)
PT_DOW=$(TZ='America/Los_Angeles' date '+%u')   # 1=Mon ... 7=Sun
PT_HR=$(TZ='America/Los_Angeles' date '+%H')    # 00-23
PT_TS=$(TZ='America/Los_Angeles' date '+%a %H:%M %Z')

# Strip leading zero to get integer comparison
PT_HR=$((10#$PT_HR))

# Classify
risk="LOW"
reason="off-peak window"

if [[ $PT_DOW -le 5 ]]; then
  # Weekday
  if [[ $PT_HR -ge 9 && $PT_HR -le 16 ]]; then
    risk="HIGH"
    reason="US business-hours peak (Mon-Fri 09:00-16:00 PT)"
  elif [[ $PT_DOW -eq 1 && $PT_HR -ge 5 && $PT_HR -le 11 ]]; then
    risk="HIGH"
    reason="Monday morning spike (deferred Friday work resuming)"
  elif [[ $PT_HR -ge 5 && $PT_HR -le 8 ]]; then
    risk="MEDIUM"
    reason="weekday morning ramp-up"
  elif [[ $PT_HR -ge 17 && $PT_HR -le 19 ]]; then
    risk="MEDIUM"
    reason="weekday business-hours tail"
  fi
fi

log "Current time: $PT_TS"
log "Risk window: $risk — $reason"

if [[ -n "$SKU" ]]; then
  log "SKU: $SKU"
fi
if [[ -n "$REGION" ]]; then
  log "Region: $REGION"
fi

# Cross-region advice if SKU/region given
if [[ "$SKU" == "Standard_D128als_v7" && "$REGION" == "westus3" ]]; then
  log ""
  log "Note: D128als_v7 in westus3 has been capacity-constrained in 2026"
  log "(2 evictions observed during v2 100T campaign 2026-05-21/22)."
  log "Consider westus2 or eastus2 if migration cost (~\$2 cross-region"
  log "solver-data snapshot copy) is acceptable for the campaign duration."
fi

log ""
log "Manual Spot Advisor check (~30 sec, portal-only — no CLI/API available):"
log "  portal.azure.com → Spot virtual machines → Compare prices and eviction rates"
log "  SKU=${SKU:-<your-sku>}  Region=${REGION:-<your-region>}"
log ""

case "$risk" in
  HIGH)
    if [[ $FORCE -eq 1 ]]; then
      log "FORCE override — proceeding with launch despite HIGH risk."
      exit 3
    fi
    log "BLOCK: HIGH-risk launch window. Recommendations:"
    log "  - Defer launch by 6-12h to reach a LOW window (overnight PT or weekend)"
    log "  - Or pass --force to override (caller acknowledges higher eviction risk)"
    log "  - For canonical runs (≥11.2T), strongly prefer LOW windows: fast-skip"
    log "    recovery cost is ~3-4h per eviction at canonical scale"
    exit 2
    ;;
  MEDIUM)
    log "PROCEED WITH AWARENESS: medium-risk window."
    log "  Acceptable for shorter runs (<6h). For long canonical campaigns,"
    log "  consider deferring to evening/weekend if scheduling allows."
    exit 1
    ;;
  LOW)
    log "OK: low-risk launch window. Proceeding."
    exit 0
    ;;
esac
