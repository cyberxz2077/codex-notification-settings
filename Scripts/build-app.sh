#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="Codex Notification Settings"
EXECUTABLE="CodexNotificationSettings"
APP="$ROOT/dist/$APP_NAME.app"
BUILD_DIR="$ROOT/.build-universal"

cd "$ROOT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$BUILD_DIR"
for arch in arm64 x86_64; do
  swiftc \
    -parse-as-library \
    -target "$arch-apple-macosx13.0" \
    -framework SwiftUI \
    -framework AppKit \
    Sources/CodexNotificationSettings/*.swift \
    -o "$BUILD_DIR/$EXECUTABLE-$arch"
done
lipo -create \
  "$BUILD_DIR/$EXECUTABLE-arm64" \
  "$BUILD_DIR/$EXECUTABLE-x86_64" \
  -output "$APP/Contents/MacOS/$EXECUTABLE"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP"

echo "$APP"
