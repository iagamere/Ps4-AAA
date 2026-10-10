#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/lib.sh"

tc="$(cat "$WORK/toolchain.txt" 2>/dev/null || echo openorbis)"
log "== compile ($tc)"
case "$tc" in
  payload-sdk)
    logged in_image 'export PS4_PAYLOAD_SDK=/opt/ps4-payload-sdk && source "$PS4_PAYLOAD_SDK/toolchain/orbis.sh" && cd /work/src/build && make -j"$(nproc)"' \
      || fail "compile/link (make) failed"
    ;;
  *)
    logged in_image 'source /opt/pacbrew/ps4/openorbis/ps4vars.sh && cd /work/src/build && make -j"$(nproc)"' \
      || fail "compile/link (make) failed"
    ;;
esac
