# Codex Notification Settings

[中文](README.md) · [English](README.en.md)

![Latest release](https://img.shields.io/github/v/release/cyberxz2077/codex-notification-settings?display_name=tag&label=latest%20release)
![CI](https://github.com/cyberxz2077/codex-notification-settings/actions/workflows/ci.yml/badge.svg)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111)
![License: MIT](https://img.shields.io/badge/license-MIT-2ea44f)

An unofficial macOS utility that turns Codex task states into recognizable sounds—so you know when work is complete, waiting for you, or failed without watching the Codex window.

<div align="center">
  <table>
    <tr>
      <td align="center" valign="middle" width="190">
        <img src="Resources/app-icon-source.png" width="160" alt="Codex Notification Settings app icon">
      </td>
      <td align="center" valign="middle">
        <img src="docs/codex-notification-settings-preview.png" width="720" alt="Codex Notification Settings settings window preview">
      </td>
    </tr>
  </table>
  <p><sub>Native SwiftUI settings UI · 原生 SwiftUI 设置界面</sub></p>
</div>

<p align="center">
  <a href="https://github.com/cyberxz2077/codex-notification-settings/releases/tag/v1.0.2"><strong>Download v1.0.2</strong></a> ·
  <a href="INSTALL.md">Install guide</a> ·
  <a href="https://github.com/cyberxz2077/codex-notification-settings/issues">Report an issue</a>
</p>

## Why this exists

Codex tasks often wait on builds, tool calls, or human approval. This utility makes those moments audible in a native macOS settings window: no settings window needs to stay open, no data is uploaded, and packaged installs do not require Python, Homebrew, or Xcode.

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

Download the recommended [v1.0.2](https://github.com/cyberxz2077/codex-notification-settings/releases/tag/v1.0.2) `Codex-Notification-Settings-1.0.2-macos.zip` from [GitHub Releases](https://github.com/cyberxz2077/codex-notification-settings/releases), unzip it, and double-click `Install.command`. See [INSTALL.md](INSTALL.md) for checksum verification and uninstall instructions.

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
./Scripts/package-release.sh 1.0.2
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

## Feedback and contributions

If this saves you from watching Codex, a Star helps other people with the same problem discover it. Sharing a useful sound mapping is welcome too.

When reporting a problem, include your macOS version, Codex version, whether you use the desktop app or CLI, and a redacted `Doctor.command` output. Never upload session records, API keys, passwords, or full personal paths.

- [Report a bug](https://github.com/cyberxz2077/codex-notification-settings/issues/new?template=bug_report.yml)
- [Request a feature](https://github.com/cyberxz2077/codex-notification-settings/issues/new?template=feature_request.yml)
- [Contribute](CONTRIBUTING.md)

## FAQ

### Is this an official OpenAI app?

No. It is a community-maintained open-source macOS utility and is not affiliated with or endorsed by OpenAI.

### Why are some states experimental?

Progress updates and realtime voice depend on Codex's local rollout JSONL format. Network, failure, and input-request states also depend on structured events emitted by the client, so they may need adaptation after Codex updates.

### Which file should I open after downloading?

Unzip the release and double-click `Install.command`. After installation, open `Codex Notification Settings.app`. Do not run `CodexNotificationEngine` directly from the release or support directory; it is a background component.

## Direction

These are exploration areas, not promised timelines: a simpler upgrade path, broader Codex client compatibility testing, and tuning default sounds and state descriptions from real user feedback.

## Disclaimer

This is an unofficial community project and is not affiliated with or endorsed by OpenAI. Codex is an OpenAI product name. Refer to the [official OpenAI Codex documentation](https://developers.openai.com/codex/) for product and configuration guidance.

## License

[MIT](LICENSE)
