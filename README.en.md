# Codex Notification Settings

[中文](README.md) · [English](README.en.md)

An unofficial macOS utility for configuring Codex notification sounds. It maps different Codex states to individually configurable system sounds, volumes, and on/off switches. The settings app can be closed after use; background notifications keep working.

<img src="Resources/app-icon-source.png" width="160" alt="Codex Notification Settings app icon">

## Features

| State | Default sound | Description |
| --- | --- | --- |
| Progress update | Pop 25% | Progress after a meaningful block of tool work; experimental |
| Final response | Hero 50% | The current task turn has ended |
| Needs you | Ping 45% | The task is waiting for an answer or approval |
| Task failed | Basso 40% | Execution could not be completed |
| Network issue | Submarine 30% | Connection loss or reconnection; experimental |
| Realtime voice | Off by default | Avoids an extra sound after a voice response; experimental |

- Configure each state independently, including sound and volume.
- Automatically preview a newly selected sound or replay it with the play button.
- Preserve and forward any existing Codex `notify` command.
- Keep the experimental progress watcher running without leaving the settings app in the Dock.
- Rate-limit duplicate notifications within the same task turn.
- Follow the first macOS preferred language: Chinese for `zh` locales and English otherwise.

## Requirements

- macOS 13 or later.
- Codex desktop or Codex CLI.
- Running a packaged build does not require Python, Homebrew, or Xcode.
- Building from source requires Xcode Command Line Tools and Swift 6.
- `terminal-notifier` is optional. Sounds still play without it, but the utility will not add its own notification banner.

## Install

### Release package (recommended)

Download the latest `Codex-Notification-Settings-<version>-macos.zip` from [GitHub Releases](https://github.com/cyberxz2077/codex-notification-settings/releases), unzip it, and double-click `Install.command`. See [INSTALL.md](INSTALL.md) for checksum verification and uninstall instructions.

### Install from source

```bash
git clone https://github.com/cyberxz2077/codex-notification-settings.git
cd codex-notification-settings
make test
./Scripts/install.sh
```

The installer:

1. Installs the settings app in `~/Applications/`.
2. Installs the native notification engine in `~/Library/Application Support/Codex Notification Settings/`.
3. Runs without a Python dependency.
4. Updates `notify` in `~/.codex/config.toml` incrementally, preserving the previous command for forwarding and uninstall recovery.
5. Installs the experimental progress watcher.

Restart Codex after installation. Sound settings are stored in `~/.codex/notification-settings.json` and take effect immediately.

To disable the experimental progress watcher during installation:

```bash
CODEX_NOTIFY_EXPERIMENTAL_STAGE=0 ./Scripts/install.sh
```

## Uninstall

```bash
./Scripts/uninstall.sh
```

The uninstaller restores the previous `notify` command only if the current command still belongs to this utility. It will not overwrite a command later installed by another tool. App and runtime files are moved to a dedicated folder in Trash; sound settings are preserved by default.

## Build and package

```bash
make build
make test
./Scripts/package-release.sh 1.0.0
```

Artifacts are written to `dist/`. The build script creates a Universal 2 app for Apple Silicon and Intel Macs. It invokes `swiftc` directly to avoid a Swift 6 compiler crash seen in some optimized SwiftUI release builds. The Swift package remains available for IDE indexing and debug builds.

Local builds use ad-hoc signing and are intended for development or personal use. A public binary release should use an Apple Developer ID certificate and notarization; otherwise Gatekeeper may prevent users from opening it directly.

## How it works

- The native Swift engine receives Codex `notify` callbacks and forwards them to any previously configured notification command.
- The same engine classifies events, deduplicates them safely across concurrent callbacks, and invokes macOS `afplay`.
- The experimental progress watcher observes new rollout JSONL records in `~/.codex/sessions/` read-only and detects progress updates after tool work.
- The SwiftUI app and background engine share one JSON configuration file; no persistent audio process is required.

## Privacy and limitations

- All processing stays on the Mac. The utility does not upload sound settings or Codex session content.
- Progress-update and realtime-voice detection depend on Codex's internal local record format and may require updates after Codex changes.
- Some client versions do not emit structured network, failure, or input-request events, so those notifications may be missed.
- The project does not read API keys, passwords, cookies, or `.env` files.

See [PRIVACY.md](PRIVACY.md) and [SECURITY.md](SECURITY.md) for the current project policies. English translations of those policy documents are still welcome.

## Disclaimer

This is an unofficial community project and is not affiliated with or endorsed by OpenAI. Codex is an OpenAI product name. Refer to the [official OpenAI Codex documentation](https://developers.openai.com/codex/) for product and configuration guidance.

## License

[MIT](LICENSE)
