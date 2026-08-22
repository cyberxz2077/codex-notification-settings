# Release process

Public macOS binaries must be signed with an Apple **Developer ID Application** certificate and notarized before publication. An ad-hoc signature is suitable only for local development.

## Prerequisites

1. Install a valid Developer ID Application certificate and private key in the login keychain.
2. Create a notarization keychain profile without committing credentials:

   ```bash
   xcrun notarytool store-credentials codex-notification-settings
   ```

3. Confirm the signing identity:

   ```bash
   security find-identity -v -p codesigning
   ```

## Build, sign, notarize, and staple

```bash
CODE_SIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)" \
NOTARY_PROFILE="codex-notification-settings" \
./Scripts/notarize-release.sh 1.0.0
```

The command produces:

- `dist/Codex-Notification-Settings-1.0.0-macos.zip`
- `dist/Codex-Notification-Settings-1.0.0-macos.zip.sha256`

Before creating the GitHub Release, verify the checksum, app version, hardened-runtime signature, stapled ticket, and Gatekeeper assessment. Publish the matching source tag and both generated files together.
