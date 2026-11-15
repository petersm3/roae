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
#   US business-hours demand for regular (non-interruptible) capacity of the same VM size. Launching
#   into peak demand means a higher chance of eviction within the first few
#   hours — which is the worst outcome for a canonical run, because the
#   fast-skip phase at resume time on a recovery VM takes ~3-4h to catch up
#   to the prior progress (estimate from the 2026-05-22 resume-phase analysis, which is not
#   reproduced in this checkout; Codex F04-022#15, FV2 D1240).
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
#   ./spot_pre_launch_check.sh --sku <vm-size> --region <region>   # context-aware advice
#   ./spot_pre_launch_check.sh --sku <vm-size> --region <region> --constrained <vm-size> <region>
#                                                 # also note a pair you know to be constrained
#
# Inputs (2026-11-15, operator decision D5): the script has no built-in VM size, region or
# resource name. --sku and --region have no default (unset, the advice prints placeholders),
# and the capacity-constrained note fires only for a pair the caller names with
# --constrained <vm-size> <region> (repeatable); it used to fire for one hard-coded pair
# from the project's own eviction history. A flag given without its value(s) is an error
# (rc 64, as for an unknown argument). The time-window check needs no cloud input.
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
#   - the 2026-05-22 resume-phase analysis (why eviction timing matters; not in this checkout)
#   - documentation/DEVELOPMENT.md §Monitor/orchestrator (ps pcpu interpretation)

set -uo pipefail

FORCE=0
SKU=""
REGION=""
QUIET=0
CONSTRAINED=()   # "<vm-size> <region>" pairs from --constrained (D5: none built in)

need_val() { [[ $1 -ge $2 ]] || { echo "missing value for $3 (expected $4)" >&2; exit 64; }; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --sku) need_val $# 2 "$1" "<vm-size>"; SKU="$2"; shift 2 ;;
    --region) need_val $# 2 "$1" "<region>"; REGION="$2"; shift 2 ;;
    --constrained) need_val $# 3 "$1" "<vm-size> <region>"; CONSTRAINED+=("$2 $3"); shift 3 ;;
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
  # Codex F04-022#12 (FV2 D1242): `-le 16` made 16:00-16:59 HIGH, while the reason string and the
  # table above put the peak at 09:00-16:00 and the MEDIUM tail from 16:00; the tail test began at 17.
  if [[ $PT_HR -ge 9 && $PT_HR -le 15 ]]; then
    risk="HIGH"
    reason="US business-hours peak (Mon-Fri 09:00-16:00 PT)"
  elif [[ $PT_DOW -eq 1 && $PT_HR -ge 5 && $PT_HR -le 11 ]]; then
    risk="HIGH"
    reason="Monday morning spike (deferred Friday work resuming)"
  elif [[ $PT_HR -ge 5 && $PT_HR -le 8 ]]; then
    risk="MEDIUM"
    reason="weekday morning ramp-up"
  elif [[ $PT_HR -ge 16 && $PT_HR -le 19 ]]; then
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

# Cross-region advice if SKU/region given and the caller named that pair as constrained
_constrained=0
for _pair in "${CONSTRAINED[@]+"${CONSTRAINED[@]}"}"; do
  [[ -n "$SKU" && -n "$REGION" && "$_pair" == "$SKU $REGION" ]] && _constrained=1
done
if [[ $_constrained -eq 1 ]]; then
  log ""
  log "Note: $SKU in $REGION was named capacity-constrained (--constrained);"
  log "Spot evictions there have been observed. Consider another region if"
  log "copying the campaign's data across regions is acceptable for the"
  log "campaign duration."
fi

log ""
log "Manual Spot Advisor check (~30 sec, portal-only — no CLI/API available):"
log "  portal.azure.com → Spot virtual machines → the eviction-rate comparison"
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
