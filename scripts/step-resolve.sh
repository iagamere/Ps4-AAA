#!/usr/bin/env bash
# Decide which zip to build. Arg 1 = optional path (workflow_dispatch input).
set -uo pipefail
: "${GITHUB_ENV:?}"
source "$(dirname "$0")/lib.sh"

log "== build started $(date -u +%FT%TZ) | event=${GITHUB_EVENT_NAME:-?} | sha=${GITHUB_SHA:-?}"
zip="${1:-}"
if [ -z "$zip" ]; then
  zip="$(git log -1 --diff-filter=AM --name-only --pretty=format: -- 'incoming/*.zip' | grep -m1 '\.zip$' || true)"
fi
[ -n "$zip" ] || fail "no zip found: push a file incoming/<name>.zip or pass the 'zip' input."
[ -f "$zip" ] || fail "zip '$zip' does not exist in the repository checkout."
echo "ZIP_PATH=$zip" >> "$GITHUB_ENV"
log "zip: $zip ($(stat -c %s "$zip") bytes)"
