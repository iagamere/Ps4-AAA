#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/lib.sh"

log "== compile"
logged in_image 'source /opt/pacbrew/ps4/openorbis/ps4vars.sh && cd /work/src/build && make -j"$(nproc)"' \
  || fail "compile/link (make) failed"
