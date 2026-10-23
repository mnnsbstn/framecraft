#!/bin/bash
set -euo pipefail
MODE="${1:-run}"
APP_NAME="FrameCraft"
BUNDLE_ID="local.sebastian.FrameCraft"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
cd "$ROOT_DIR"
if ! /usr/bin/xcrun swift --version; then
  echo 'Xcode muss zuerst vollständig eingerichtet sein. Öffne Xcode und prüfe den Lizenzdialog.' >&2
  exit 69
fi
case "$MODE" in
  run|--verify|--logs|--debug|--build|--test) ;;
  *) echo "usage: $0 [run|--verify|--logs|--debug|--build|--test]" >&2; exit 2 ;;
esac
if [ "$MODE" = '--test' ]; then
  exec /usr/bin/xcrun swift test --scratch-path "$ROOT_DIR/.build"
fi
# Stop only this project's running bundle, never another recording application.
if [ "$MODE" != '--build' ]; then
  if /usr/bin/pgrep -f "$APP_BUNDLE/Contents/MacOS/$APP_NAME" >/dev/null; then
    echo 'FrameCraft läuft bereits. Bitte laufende Aufnahme beenden und die App schließen, dann erneut starten.' >&2
    exit 1
  fi
fi
/usr/bin/xcrun swift build -c release --scratch-path "$ROOT_DIR/.build"
BUILD_DIR="$(/usr/bin/xcrun swift build -c release --scratch-path "$ROOT_DIR/.build" --show-bin-path)"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>$APP_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.3.0</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSMicrophoneUsageDescription</key><string>FrameCraft nimmt auf deinen Wunsch gesprochenen Ton zum Bildschirmvideo auf.</string>
<key>NSScreenCaptureUsageDescription</key><string>FrameCraft zeichnet den von dir ausgewählten Bildschirm oder ein Fenster auf.</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
/usr/bin/codesign --force --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE"
case "$MODE" in
  --build) echo "$APP_BUNDLE" ;;
  --debug) /usr/bin/xcrun lldb "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  --logs) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "FrameCraft"' ;;
  --verify) /usr/bin/open -n "$APP_BUNDLE"; sleep 2; /usr/bin/pgrep -f "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
esac
