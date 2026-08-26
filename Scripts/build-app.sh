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
ZIP_PATH="$PROJECT_DIR/dist/Legion-M600-Manager-macOS-arm64.zip"
HASH_PATH="$PROJECT_DIR/dist/SHA256SUMS"

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources" "$PROJECT_DIR/dist"
cp "$BIN_DIR/M600 Manager" "$CONTENTS_DIR/MacOS/M600 Manager"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$BIN_DIR/m600ctl" "$PROJECT_DIR/dist/m600ctl"
codesign --force --deep --sign - "$APP_DIR"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

cd "$PROJECT_DIR/dist"
shasum -a 256 \
  "Legion M600 Manager.app/Contents/MacOS/M600 Manager" \
  m600ctl \
  "Legion-M600-Manager-macOS-arm64.zip" > "$HASH_PATH"

echo "Built: $APP_DIR"
echo "CLI:   $PROJECT_DIR/dist/m600ctl"
echo "Archive: $ZIP_PATH"
echo "Hashes:  $HASH_PATH"
