#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
VERSION="${1:-1.0.0}"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:?Set CODE_SIGN_IDENTITY to a Developer ID Application identity}"
NOTARY_PROFILE="${NOTARY_PROFILE:?Set NOTARY_PROFILE to an xcrun notarytool keychain profile}"
ZIP_PATH="$ROOT/dist/Codex-Notification-Settings-$VERSION-macos.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"
STAGING_DIR=$(mktemp -d "$ROOT/dist/.notarize-$VERSION.XXXXXX")
RELEASE_DIR="$STAGING_DIR/Codex-Notification-Settings-$VERSION"
APP="$RELEASE_DIR/Codex Notification Settings.app"

CODE_SIGN_IDENTITY="$SIGN_IDENTITY" "$ROOT/Scripts/package-release.sh" "$VERSION"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

ditto -x -k "$ZIP_PATH" "$STAGING_DIR"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=2 "$APP"

rm "$ZIP_PATH"
ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "$RELEASE_DIR" "$ZIP_PATH"
(
  cd "${ZIP_PATH:h}"
  shasum -a 256 "${ZIP_PATH:t}" > "${CHECKSUM_PATH:t}"
)

echo "$ZIP_PATH"
echo "$CHECKSUM_PATH"
