#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
SOURCE_IMAGE=${1:-"$PROJECT_DIR/Resources/AppIcon.png"}
MASTER_PATH="$PROJECT_DIR/Resources/AppIcon.png"
ICNS_PATH="$PROJECT_DIR/Resources/AppIcon.icns"

if [[ ! -f "$SOURCE_IMAGE" ]]; then
  echo "Source image not found: $SOURCE_IMAGE" >&2
  exit 1
fi

WIDTH=$(sips -g pixelWidth "$SOURCE_IMAGE" | awk '/pixelWidth/ { print $2 }')
HEIGHT=$(sips -g pixelHeight "$SOURCE_IMAGE" | awk '/pixelHeight/ { print $2 }')
if [[ -z "$WIDTH" || -z "$HEIGHT" || "$WIDTH" -le 0 || "$HEIGHT" -le 0 ]]; then
  echo "Could not read source-image dimensions: $SOURCE_IMAGE" >&2
  exit 1
fi

CANVAS_SIZE=$((WIDTH > HEIGHT ? WIDTH : HEIGHT))
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# App icons must be square. Padding the shorter dimension keeps the supplied artwork's geometry
# intact; `sips` retains transparency when the source image has an alpha channel.
sips --padToHeightWidth "$CANVAS_SIZE" "$CANVAS_SIZE" "$SOURCE_IMAGE" \
  --out "$TEMP_DIR/padded.png" >/dev/null
sips --resampleHeightWidth 1024 1024 "$TEMP_DIR/padded.png" \
  --out "$TEMP_DIR/AppIcon.png" >/dev/null

ICONSET_DIR="$TEMP_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

generate_icon() {
  local filename=$1
  local size=$2
  sips --resampleHeightWidth "$size" "$size" "$TEMP_DIR/AppIcon.png" \
    --out "$ICONSET_DIR/$filename" >/dev/null
}

generate_icon icon_16x16.png 16
generate_icon icon_16x16@2x.png 32
generate_icon icon_32x32.png 32
generate_icon icon_32x32@2x.png 64
generate_icon icon_128x128.png 128
generate_icon icon_128x128@2x.png 256
generate_icon icon_256x256.png 256
generate_icon icon_256x256@2x.png 512
generate_icon icon_512x512.png 512
generate_icon icon_512x512@2x.png 1024

cp "$TEMP_DIR/AppIcon.png" "$MASTER_PATH"
iconutil --convert icns "$ICONSET_DIR" --output "$ICNS_PATH"

echo "Master: $MASTER_PATH"
echo "Icon:   $ICNS_PATH"
