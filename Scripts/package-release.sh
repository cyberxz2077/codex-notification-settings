#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
VERSION="${1:-1.0.0}"
STAGING_DIR=$(mktemp -d "$ROOT/dist/.release-$VERSION.XXXXXX")
RELEASE_DIR="$STAGING_DIR/Codex-Notification-Settings-$VERSION"
ZIP_PATH="$ROOT/dist/Codex-Notification-Settings-$VERSION-macos.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

"$ROOT/Scripts/build-app.sh" "$VERSION" >/dev/null
mkdir -p "$RELEASE_DIR"
ditto "$ROOT/dist/Codex Notification Settings.app" "$RELEASE_DIR/Codex Notification Settings.app"
cp "$ROOT/Scripts/install.sh" "$RELEASE_DIR/Install.command"
cp "$ROOT/Scripts/uninstall.sh" "$RELEASE_DIR/Uninstall.command"
cp "$ROOT/Scripts/doctor.sh" "$RELEASE_DIR/Doctor.command"
cp \
  "$ROOT/README.md" \
  "$ROOT/README.en.md" \
  "$ROOT/INSTALL.md" \
  "$ROOT/RELEASE.md" \
  "$ROOT/CHANGELOG.md" \
  "$ROOT/PRIVACY.md" \
  "$ROOT/SECURITY.md" \
  "$ROOT/LICENSE" \
  "$RELEASE_DIR/"
mkdir -p "$RELEASE_DIR/Resources"
cp "$ROOT/Resources/notification-settings.default.json" "$RELEASE_DIR/Resources/"
chmod +x \
  "$RELEASE_DIR/Install.command" \
  "$RELEASE_DIR/Uninstall.command" \
  "$RELEASE_DIR/Doctor.command"

if [[ -f "$ZIP_PATH" ]]; then
  rm "$ZIP_PATH"
fi
ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent \
  "$RELEASE_DIR" \
  "$ZIP_PATH"

(
  cd "${ZIP_PATH:h}"
  shasum -a 256 "${ZIP_PATH:t}" > "${CHECKSUM_PATH:t}"
)

echo "$ZIP_PATH"
echo "$CHECKSUM_PATH"
