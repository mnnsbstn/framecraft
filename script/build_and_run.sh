#!/bin/bash
set -euo pipefail
MODE="${1:-run}"
APP_NAME="FrameCraft"
BUNDLE_ID="local.sebastian.FrameCraft"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
SIGNING_PIN="$HOME/Library/Application Support/FrameCraft/Signing/identity.sha1"
cd "$ROOT_DIR"
case "$MODE" in
  run|--verify|--logs|--debug|--build|--test|--launch|--diagnose) ;;
  *) echo "usage: $0 [run|--verify|--logs|--debug|--build|--test|--launch|--diagnose]" >&2; exit 2 ;;
esac
if [ "$MODE" = '--launch' ]; then
  [ -d "$APP_BUNDLE" ] || { echo 'Bitte FrameCraft zuerst mit --build erstellen.' >&2; exit 66; }
  /usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
  exec /usr/bin/open "$APP_BUNDLE"
fi
if [ "$MODE" = '--diagnose' ]; then
  echo "App: $APP_BUNDLE"
  /usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
  /usr/bin/codesign --display --verbose=2 -r- "$APP_BUNDLE"
  /usr/bin/security find-identity -p codesigning -v
  if [ -f "$SIGNING_PIN" ]; then printf 'Gespeicherte lokale Identität: '; cat "$SIGNING_PIN"; fi
  exit 0
fi
if ! /usr/bin/xcrun swift --version; then
  echo 'Xcode muss zuerst vollständig eingerichtet sein. Öffne Xcode und prüfe den Lizenzdialog.' >&2
  exit 69
fi
if [ "$MODE" = '--test' ]; then
  exec /usr/bin/xcrun swift test --scratch-path "$ROOT_DIR/.build"
fi
# Refuse every bundle replacement while FrameCraft is running, including --build.
# A process-query failure is not proof that it is safe to replace the app.
ensure_stopped() {
  local status=0
  /usr/bin/pgrep -x "$APP_NAME" >/dev/null || status=$?
  if [ "$status" = 0 ]; then
    echo 'FrameCraft läuft bereits. Bitte Aufnahme/Export beenden, Projekt speichern und die App schließen. Zum unveränderten Öffnen: --launch.' >&2
    exit 1
  elif [ "$status" != 1 ]; then
    echo 'Laufende Apps konnten nicht geprüft werden. Die vorhandene App bleibt unverändert.' >&2
    exit 1
  fi
}
ensure_stopped
if [ "${FRAMECRAFT_SIGNING_IDENTITY+x}" = x ]; then
  SIGN_IDENTITY="$FRAMECRAFT_SIGNING_IDENTITY"
  [ -n "$SIGN_IDENTITY" ] || { echo 'Leere Signierungsidentität; Abbruch.' >&2; exit 1; }
elif [ -f "$SIGNING_PIN" ]; then
  SIGN_IDENTITY="$(cat "$SIGNING_PIN")"
  [[ "$SIGN_IDENTITY" =~ ^[A-Fa-f0-9]{40}$ ]] || { echo 'Ungültige lokale Signierungskennung; kein Rückfall auf ad hoc.' >&2; exit 1; }
else
  echo 'Feste Signierung fehlt. Einmalig python3 script/setup-local-signing.py ausführen oder FRAMECRAFT_SIGNING_IDENTITY ausdrücklich setzen.' >&2
  exit 1
fi
EXISTING_ADHOC=0
if [ -d "$APP_BUNDLE" ]; then
  /usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
  EXISTING_SIGNATURE="$(/usr/bin/codesign --display --verbose=2 "$APP_BUNDLE" 2>&1)"
  if /usr/bin/grep -q '^Signature=adhoc$' <<< "$EXISTING_SIGNATURE"; then
    EXISTING_ADHOC=1
    if [ "$SIGN_IDENTITY" != '-' ] && [ "${FRAMECRAFT_MIGRATE_ADHOC:-0}" != 1 ]; then
      echo 'Einmaliger Wechsel von ad hoc zu fester Signierung: FRAMECRAFT_MIGRATE_ADHOC=1 setzen. macOS kann hierfür einmalig eine neue Freigabe verlangen.' >&2
      exit 1
    fi
  elif [ "$SIGN_IDENTITY" = '-' ]; then
    echo 'Die vorhandene App ist fest signiert. Ein Rückfall auf ad hoc wird verweigert.' >&2
    exit 1
  fi
fi
if [ "$SIGN_IDENTITY" = '-' ]; then
  echo 'Lokaler Entwicklungsbuild: Nach Änderungen kann macOS die Bildschirmfreigabe erneut verlangen.' >&2
fi
/usr/bin/xcrun swift build -c release --scratch-path "$ROOT_DIR/.build"
BUILD_DIR="$(/usr/bin/xcrun swift build -c release --scratch-path "$ROOT_DIR/.build" --show-bin-path)"
mkdir -p "$ROOT_DIR/dist"
STAGING_DIR="$(/usr/bin/mktemp -d "$ROOT_DIR/dist/.framecraft-stage.XXXXXX")"
trap '/bin/rm -rf "$STAGING_DIR"' EXIT
STAGED_APP="$STAGING_DIR/$APP_NAME.app"
mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$STAGED_APP/Contents/MacOS/$APP_NAME"
chmod +x "$STAGED_APP/Contents/MacOS/$APP_NAME"
cat > "$STAGED_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>$APP_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.3.2</string>
<key>CFBundleVersion</key><string>6</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSMicrophoneUsageDescription</key><string>FrameCraft nimmt auf deinen Wunsch gesprochenen Ton zum Bildschirmvideo auf.</string>
<key>NSScreenCaptureUsageDescription</key><string>FrameCraft zeichnet den von dir ausgewählten Bildschirm oder ein Fenster auf.</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
/usr/bin/codesign --force --sign "$SIGN_IDENTITY" --identifier "$BUNDLE_ID" "$STAGED_APP"
/usr/bin/codesign --verify --deep --strict "$STAGED_APP"
# A stable update must satisfy the old identity AND the reverse requirement.
# Reject incompatible or broadened identities before moving the working app.
if [ -d "$APP_BUNDLE" ] && [ "$EXISTING_ADHOC" = 0 ]; then
  /usr/bin/codesign --display -r- "$APP_BUNDLE" 2>&1 | /usr/bin/sed -n 's/^#* *designated => //p' > "$STAGING_DIR/previous.req"
  /usr/bin/codesign --display -r- "$STAGED_APP" 2>&1 | /usr/bin/sed -n 's/^#* *designated => //p' > "$STAGING_DIR/next.req"
  [ -s "$STAGING_DIR/previous.req" ] && [ -s "$STAGING_DIR/next.req" ] || { echo 'Signierungsanforderungen fehlen; Abbruch.' >&2; exit 1; }
  /usr/bin/codesign --verify --strict -R "$STAGING_DIR/previous.req" "$STAGED_APP"
  /usr/bin/codesign --verify --strict -R "$STAGING_DIR/next.req" "$APP_BUNDLE"
fi
ensure_stopped
# Keep the previous bundle recoverable; never overwrite it before signing succeeds.
BACKUP_DIR=""
if [ -d "$APP_BUNDLE" ]; then
  BACKUP_DIR="$(/usr/bin/mktemp -d "$ROOT_DIR/dist/.framecraft-backup.XXXXXX")"
  mv "$APP_BUNDLE" "$BACKUP_DIR/$APP_NAME.app"
fi
if ! mv "$STAGED_APP" "$APP_BUNDLE"; then
  if [ -n "$BACKUP_DIR" ]; then mv "$BACKUP_DIR/$APP_NAME.app" "$APP_BUNDLE"; fi
  exit 1
fi
if [ -n "$BACKUP_DIR" ]; then echo "Vorherige App gesichert: $BACKUP_DIR/$APP_NAME.app"; fi
case "$MODE" in
  --build) echo "$APP_BUNDLE" ;;
  --debug) /usr/bin/xcrun lldb "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  --logs) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "FrameCraft"' ;;
  --verify) /usr/bin/open -n "$APP_BUNDLE"; sleep 2; /usr/bin/pgrep -f "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
esac
