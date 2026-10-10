#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/lib.sh"

log "== configure"
logged in_image 'source /opt/pacbrew/ps4/openorbis/ps4vars.sh && cd /work/src && rm -rf build && mkdir build && cd build && openorbis-cmake ..' \
  || fail "configure (openorbis-cmake ..) failed"
