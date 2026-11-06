#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Assets/AppIcon.png"
OUTPUT="${1:-$ROOT_DIR/Assets/AppIcon.icns}"
[ -f "$SOURCE" ] || { echo 'App-Icon fehlt: Assets/AppIcon.png' >&2; exit 66; }
WIDTH=$(/usr/bin/sips -g pixelWidth "$SOURCE" | /usr/bin/awk '/pixelWidth/ {print $2}')
HEIGHT=$(/usr/bin/sips -g pixelHeight "$SOURCE" | /usr/bin/awk '/pixelHeight/ {print $2}')
[ "$WIDTH" = "$HEIGHT" ] && [ "$WIDTH" -ge 1024 ] || { echo 'Das App-Icon muss quadratisch und mindestens 1024 Pixel groß sein.' >&2; exit 65; }
TEMP_DIR=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/framecraft-icon.XXXXXX")
trap '/bin/rm -rf "$TEMP_DIR"' EXIT
ICONSET="$TEMP_DIR/AppIcon.iconset"
mkdir -p "$ICONSET" "$(dirname "$OUTPUT")"
for SIZE in 16 32 128 256 512; do
  /usr/bin/sips -z "$SIZE" "$SIZE" "$SOURCE" --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
  DOUBLE=$((SIZE * 2))
  /usr/bin/sips -z "$DOUBLE" "$DOUBLE" "$SOURCE" --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
/usr/bin/iconutil -c icns "$ICONSET" -o "$TEMP_DIR/AppIcon.icns"
# Replace only after iconutil has successfully produced a complete resource.
cp "$TEMP_DIR/AppIcon.icns" "$OUTPUT"
