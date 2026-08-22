#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
VERSION="${1:-1.0.0}"
STAGING_DIR=$(mktemp -d "$ROOT/dist/.release-$VERSION.XXXXXX")
RELEASE_DIR="$STAGING_DIR/Codex-Notification-Settings-$VERSION"
ZIP_PATH="$ROOT/dist/Codex-Notification-Settings-$VERSION-macos.zip"

"$ROOT/Scripts/build-app.sh" >/dev/null
mkdir -p "$RELEASE_DIR"
ditto "$ROOT/dist/Codex Notification Settings.app" "$RELEASE_DIR/Codex Notification Settings.app"
cp "$ROOT/Scripts/install.sh" "$RELEASE_DIR/Install.command"
cp "$ROOT/Scripts/uninstall.sh" "$RELEASE_DIR/Uninstall.command"
cp "$ROOT/README.md" "$ROOT/LICENSE" "$RELEASE_DIR/"
mkdir -p "$RELEASE_DIR/Resources"
cp "$ROOT/Resources/notification-settings.default.json" "$RELEASE_DIR/Resources/"
chmod +x "$RELEASE_DIR/Install.command" "$RELEASE_DIR/Uninstall.command"

if [[ -f "$ZIP_PATH" ]]; then
  rm "$ZIP_PATH"
fi
ditto -c -k --sequesterRsrc --keepParent \
  "$RELEASE_DIR" \
  "$ZIP_PATH"

echo "$ZIP_PATH"
