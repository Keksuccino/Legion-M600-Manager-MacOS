#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
export DEVELOPER_DIR

cd "$PROJECT_DIR"
swift build -c release --product "M600 Manager"
swift build -c release --product m600ctl

BIN_DIR=$(swift build -c release --show-bin-path)
APP_DIR="$PROJECT_DIR/dist/Legion M600 Manager.app"
CONTENTS_DIR="$APP_DIR/Contents"
DMG_PATH="$PROJECT_DIR/dist/Legion-M600-Manager-macOS-arm64.dmg"
HASH_PATH="$PROJECT_DIR/dist/SHA256SUMS"
DMG_STAGING_DIR=$(mktemp -d -t legion-m600-manager-dmg)

cleanup() {
  rm -rf "$DMG_STAGING_DIR"
}
trap cleanup EXIT

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources" "$PROJECT_DIR/dist"
cp "$BIN_DIR/M600 Manager" "$CONTENTS_DIR/MacOS/M600 Manager"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$CONTENTS_DIR/Resources/AppIcon.icns"
cp "$BIN_DIR/m600ctl" "$PROJECT_DIR/dist/m600ctl"
codesign --force --deep --sign - "$APP_DIR"
# Finder caches bundle icons against the package directory metadata. Refresh the root timestamp
# after replacing resources inside an existing app so local rebuilds show a new icon immediately.
touch "$APP_DIR"
rm -f "$DMG_PATH"
ditto "$APP_DIR" "$DMG_STAGING_DIR/Legion M600 Manager.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
hdiutil create \
  -quiet \
  -volname "Legion M600 Manager" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

cd "$PROJECT_DIR/dist"
shasum -a 256 \
  "Legion M600 Manager.app/Contents/MacOS/M600 Manager" \
  m600ctl \
  "Legion-M600-Manager-macOS-arm64.dmg" > "$HASH_PATH"

echo "Built: $APP_DIR"
echo "CLI:   $PROJECT_DIR/dist/m600ctl"
echo "Disk image: $DMG_PATH"
echo "Hashes:  $HASH_PATH"
