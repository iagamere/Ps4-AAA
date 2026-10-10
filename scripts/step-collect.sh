#!/usr/bin/env bash
# Always runs. Produces: $OUT/status.json, $OUT/errors.txt (on failure), $OUT/<name>.elf (on success)
set -uo pipefail
source "$(dirname "$0")/lib.sh"

ok=false; elf=""; version=""
log "toolchain used: $(cat "$WORK/toolchain.txt" 2>/dev/null || echo unknown)"
if [ "${BUILD_FAILED:-}" != "true" ]; then
  found="$(find "$WORK/src/build" -name '*.elf' -not -path '*/CMakeFiles/*' 2>/dev/null)"
  pick="$(printf '%s\n' "$found" | grep -E '/ezremote-server-[^/]*\.elf$' | head -1)"
  [ -n "$pick" ] || pick="$(printf '%s\n' "$found" | head -1)"
  if [ -z "$pick" ]; then
    log "ERROR: build finished but no .elf file exists under build/ (expected ezremote-server-<version>.elf)."
    echo "BUILD_FAILED=true" >> "$GITHUB_ENV"
  else
    elf="$(basename "$pick")"
    cp "$pick" "$OUT/$elf"
    version="$(printf '%s' "$elf" | sed -E 's/^ezremote-server-//; s/\.elf$//')"
    [ "$version" != "$elf" ] || version=""
    ok=true
    log "elf: $elf ($(stat -c %s "$OUT/$elf") bytes)  version: ${version:-?}"
  fi
fi

python3 - "$OUT" "$ok" "$version" "$elf" <<'PY'
import json, sys, datetime
out, ok, version, elf = sys.argv[1:5]
json.dump({"ok": ok == "true", "version": version, "elf": elf,
           "time": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")},
          open(out + "/status.json", "w"), ensure_ascii=False)
PY

if [ "$ok" != "true" ]; then
  python3 "$(dirname "$0")/extract_errors.py" "$LOG" "$OUT/errors.txt"
fi
cat "$OUT/status.json"; echo
