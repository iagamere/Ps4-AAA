#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/lib.sh"

owner="${GITHUB_REPOSITORY_OWNER,,}"
image="ghcr.io/${owner}/ps4-toolchain:latest"
echo "$image" > "$IMAGE_FILE"
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin >/dev/null 2>&1 \
  || fail "docker login to ghcr.io failed"
logged docker pull "$image" \
  || fail "cannot pull $image - run the 'toolchain' workflow once first (and make sure it finished successfully)."
