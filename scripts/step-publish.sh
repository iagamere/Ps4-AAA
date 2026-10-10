#!/usr/bin/env bash
# Always runs. Arg 1 = run number. Creates release build-<n> with status.json + log (+ elf / errors.txt).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
tag="build-$1"

[ -f "$OUT/status.json" ] || echo '{"ok":false,"version":"","elf":"","time":""}' > "$OUT/status.json"
files=("$OUT/build.log" "$OUT/status.json")
ls "$OUT"/*.elf >/dev/null 2>&1 && files+=("$OUT"/*.elf)
[ -f "$OUT/errors.txt" ] && files+=("$OUT/errors.txt")

state="$(python3 -c "import json;print('success' if json.load(open('$OUT/status.json'))['ok'] else 'FAILED')")"
gh release delete "$tag" --yes --cleanup-tag >/dev/null 2>&1 || true   # re-run of the same run number
gh release create "$tag" "${files[@]}" \
  --target "$GITHUB_SHA" --title "$tag" \
  --notes "Build $1 - $state. Source zip: ${ZIP_PATH:-unknown}" \
  || { echo "ERROR: could not create release $tag"; exit 1; }
echo "release $tag created with: ${files[*]}"
