#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/lib.sh"

tc="$(cat "$WORK/toolchain.txt" 2>/dev/null || echo openorbis)"
log "== configure ($tc)"
case "$tc" in
  payload-sdk)
    # orbis-clang adds -L<sysroot>/user/homebrew/lib but NOT the matching -I, so add it for the project's own cmake run.
    logged in_image 'export PS4_PAYLOAD_SDK=/opt/ps4-payload-sdk && source "$PS4_PAYLOAD_SDK/toolchain/orbis.sh" && export CFLAGS="-I$PS4_SYSROOT$PS4_HBROOT/include" CXXFLAGS="-I$PS4_SYSROOT$PS4_HBROOT/include" && cd /work/src && rm -rf build && mkdir build && cd build && "$CMAKE" ..' \
      || fail "configure (orbis-cmake ..) failed"
    ;;
  *)
    logged in_image 'source /opt/pacbrew/ps4/openorbis/ps4vars.sh && cd /work/src && rm -rf build && mkdir build && cd build && openorbis-cmake ..' \
      || fail "configure (openorbis-cmake ..) failed"
    ;;
esac
