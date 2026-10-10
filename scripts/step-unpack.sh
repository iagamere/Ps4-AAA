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

# toolchain.txt (optional, project root): "openorbis" (default) or "payload-sdk"
tc=""; tc_src="default"
for f in "$WORK/src/toolchain.txt" "$WORK/unz/toolchain.txt"; do
  if [ -f "$f" ]; then
    tc="$(head -n1 "$f" | tr -d '\r' | tr 'A-Z' 'a-z' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    tc_src="${f#"$WORK/"}"
    break
  fi
done
[ -n "$tc" ] || tc="openorbis"
case "$tc" in
  openorbis|payload-sdk) ;;
  *) fail "toolchain.txt must contain exactly 'openorbis' or 'payload-sdk' (found: '$tc' in $tc_src)" ;;
esac
echo "$tc" > "$WORK/toolchain.txt"
log "toolchain: $tc (from $tc_src)"
