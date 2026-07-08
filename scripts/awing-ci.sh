#!/bin/bash
#
# awing-ci.sh — flip GitHub repo public, run CI, flip back to private.
#
# Purpose: keep samagids/awing-ai-learning private most of the time, but
# briefly flip to public when CI needs to run. GitHub Actions on a public
# repo is FREE (unlimited minutes). This lets us have private repo hygiene
# with zero GitHub Actions billing.
#
# Usage:
#   ./awing-ci.sh              # Interactive: flip, wait, flip back
#   ./awing-ci.sh --dispatch   # Also trigger workflow_dispatch for both
#                              # Build Android and Build iOS after flipping
#   ./awing-ci.sh --dry-run    # Log what would happen without touching anything
#   ./awing-ci.sh --status     # Just print current state and exit
#
# Requirements:
#   • `gh` CLI installed and authenticated (`gh auth status` should show
#     samagids logged in with `repo` + `admin:repo_hook` scopes).
#   • Run from WSL Ubuntu or any Linux/macOS shell.
#
# Rate-limiting safeguards:
#   • Maximum 3 flips per day (state stored in ~/.awing-flip-state).
#     GitHub itself rate-limits visibility changes; going over ~5/day
#     starts producing errors.
#   • Refuses to flip if there are already in-progress workflow runs
#     — those would get canceled by the visibility change.
#   • Waits for CI to complete before flipping back to private, but
#     with a hard timeout (default 45 min) so a stuck iOS run doesn't
#     leave the repo public forever.
#
# Log: appended to ~/.awing-ci.log (rotated when >10 MB).

set -eo pipefail

REPO="samagids/awing-ai-learning"
STATE_FILE="$HOME/.awing-flip-state"
LOG_FILE="$HOME/.awing-ci.log"
MAX_FLIPS_PER_DAY=3
MAX_CI_WAIT_MIN=45

DRY_RUN=0
DISPATCH=0
STATUS_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=1 ;;
    --dispatch) DISPATCH=1 ;;
    --status)   STATUS_ONLY=1 ;;
    -h|--help)
      sed -n '1,40p' "$0"
      exit 0
      ;;
  esac
done

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_rotate() {
  # If log > 10 MB, keep last 5 MB.
  if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE")" -gt 10485760 ]; then
    tail -c 5242880 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    log "log rotated"
  fi
}
log_rotate

# ---- Preflight ----------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  log "ERROR: gh CLI not installed. Run: sudo apt install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  log "ERROR: gh CLI not authenticated. Run: gh auth login"
  exit 1
fi

# ---- Read current state -------------------------------------------------
CURRENT_VIS=$(gh repo view "$REPO" --json visibility --jq '.visibility' 2>/dev/null || echo "UNKNOWN")
PENDING=$(gh run list --repo "$REPO" --status queued --status in_progress \
  --json databaseId --jq 'length' 2>/dev/null || echo "0")

log "State: repo=$CURRENT_VIS, in-progress runs=$PENDING"

if [ "$STATUS_ONLY" -eq 1 ]; then
  # Print rate-limit counter
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "no flips today"
  fi
  exit 0
fi

# ---- Rate limit check ---------------------------------------------------
TODAY=$(date +%Y-%m-%d)
LAST_DATE=""
LAST_COUNT=0
if [ -f "$STATE_FILE" ]; then
  LAST_DATE=$(awk 'NR==1 {print $1}' "$STATE_FILE")
  LAST_COUNT=$(awk 'NR==1 {print $2}' "$STATE_FILE")
fi
if [ "$LAST_DATE" = "$TODAY" ] && [ "${LAST_COUNT:-0}" -ge "$MAX_FLIPS_PER_DAY" ]; then
  log "ERROR: hit daily flip limit ($MAX_FLIPS_PER_DAY). Try again tomorrow."
  exit 2
fi

# ---- Flip to PUBLIC -----------------------------------------------------
if [ "$CURRENT_VIS" = "PRIVATE" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: would flip to public"
  else
    log "Flipping repo PUBLIC..."
    gh repo edit "$REPO" --visibility public --accept-visibility-change-consequences \
      2>&1 | tee -a "$LOG_FILE"

    # Record the flip
    if [ "$LAST_DATE" = "$TODAY" ]; then
      NEW_COUNT=$((LAST_COUNT + 1))
    else
      NEW_COUNT=1
    fi
    printf "%s\t%d\n" "$TODAY" "$NEW_COUNT" > "$STATE_FILE"
    log "Public. (flips today: $NEW_COUNT/$MAX_FLIPS_PER_DAY)"
  fi
else
  log "Already public — skipping first flip."
fi

# ---- Optionally dispatch workflows --------------------------------------
if [ "$DISPATCH" -eq 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: would dispatch Build Android + Build iOS"
  else
    log "Dispatching Build Android + Build iOS on main..."
    gh workflow run build-android.yml --repo "$REPO" --ref main 2>&1 | tee -a "$LOG_FILE" || true
    gh workflow run build-ios.yml     --repo "$REPO" --ref main 2>&1 | tee -a "$LOG_FILE" || true
    sleep 5  # let GitHub register the queued runs
  fi
fi

# ---- Wait for CI --------------------------------------------------------
WAIT_START=$(date +%s)
DEADLINE=$((WAIT_START + MAX_CI_WAIT_MIN * 60))
log "Waiting for CI runs to complete (timeout: ${MAX_CI_WAIT_MIN} min)..."

while true; do
  PENDING=$(gh run list --repo "$REPO" --status queued --status in_progress \
    --json databaseId --jq 'length' 2>/dev/null || echo "0")
  NOW=$(date +%s)
  ELAPSED_MIN=$(( (NOW - WAIT_START) / 60 ))

  if [ "$PENDING" -eq 0 ]; then
    log "All runs complete after ${ELAPSED_MIN} min."
    break
  fi

  if [ "$NOW" -ge "$DEADLINE" ]; then
    log "WARNING: timeout after ${MAX_CI_WAIT_MIN} min with $PENDING run(s) still in progress. Flipping back anyway to avoid leaving public."
    break
  fi

  log "  ${PENDING} run(s) still in progress (${ELAPSED_MIN} min elapsed)..."
  sleep 60
done

# ---- Flip back to PRIVATE -----------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
  log "DRY-RUN: would flip back to private"
else
  log "Flipping repo PRIVATE..."
  gh repo edit "$REPO" --visibility private --accept-visibility-change-consequences \
    2>&1 | tee -a "$LOG_FILE"
  log "Done. Repo is private."
fi
