#!/usr/bin/env bash
# Shared helpers. Sourced by the step scripts.
# Every failure message MUST contain "ERROR:" so that errors.txt picks it up.
OUT="${OUT:?OUT not set}"
WORK="${WORK:?WORK not set}"
LOG="$OUT/build.log"
mkdir -p "$OUT" "$WORK"

log()  { echo "$*" | tee -a "$LOG"; }
fail() { log "ERROR: $*"; echo "BUILD_FAILED=true" >> "$GITHUB_ENV"; exit 0; }   # exit 0: later steps still run, job fails at the end

# run a command, append everything to build.log, return its exit code
logged() { "$@" 2>&1 | tee -a "$LOG"; return "${PIPESTATUS[0]}"; }

# run a command inside the toolchain image with the work dir mounted
IMAGE_FILE="$WORK/image.txt"
in_image() {
  local image; image="$(cat "$IMAGE_FILE")"
  docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
    -v "$WORK:/work" -w /work "$image" bash -o pipefail -c "$1"
}
