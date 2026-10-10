#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/lib.sh"

tc="$(cat "$WORK/toolchain.txt" 2>/dev/null || echo openorbis)"
owner="${GITHUB_REPOSITORY_OWNER,,}"
case "$tc" in
  payload-sdk) image="ghcr.io/${owner}/ps4-payload-toolchain:latest"; wf="toolchain-payload" ;;
  *)           image="ghcr.io/${owner}/ps4-toolchain:latest";         wf="toolchain" ;;
esac
echo "$image" > "$IMAGE_FILE"
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin >/dev/null 2>&1 \
  || fail "docker login to ghcr.io failed"
logged docker pull "$image" \
  || fail "cannot pull $image - run the '$wf' workflow once first (and make sure it finished successfully)."
