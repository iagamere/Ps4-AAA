#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/lib.sh"

rm -rf "$WORK/unz" "$WORK/src"; mkdir -p "$WORK/unz"
logged unzip -q -o "$ZIP_PATH" -d "$WORK/unz" || fail "unzip failed for $ZIP_PATH"

# shallowest directory that contains a CMakeLists.txt
cm="$(find "$WORK/unz" -name CMakeLists.txt -not -path '*/__MACOSX/*' -printf '%d %p\n' | sort -n | head -1 | cut -d' ' -f2-)"
[ -n "$cm" ] || fail "CMakeLists.txt not found anywhere inside $ZIP_PATH"
srcdir="$(dirname "$cm")"
mv "$srcdir" "$WORK/src"
log "project dir: ${srcdir#"$WORK/unz/"} (CMakeLists.txt found)"
