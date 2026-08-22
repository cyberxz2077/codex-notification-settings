#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
if [[ -d "$SCRIPT_DIR/Codex Notification Settings.app" || -f "$SCRIPT_DIR/Package.swift" ]]; then
  ROOT="$SCRIPT_DIR"
else
  ROOT="${SCRIPT_DIR:h}"
fi
APP_NAME="Codex Notification Settings"
APP_SOURCE="$ROOT/dist/$APP_NAME.app"
if [[ -d "$ROOT/$APP_NAME.app" ]]; then
  APP_SOURCE="$ROOT/$APP_NAME.app"
fi
APP_TARGET="$HOME/Applications/$APP_NAME.app"
SUPPORT_DIR="$HOME/Library/Application Support/Codex Notification Settings"
ENGINE_DIR="$SUPPORT_DIR/Engine"
ENGINE="$ENGINE_DIR/CodexNotificationEngine"
LOG_DIR="$HOME/Library/Logs/Codex Notification Settings"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME/config.toml"
SETTINGS_FILE="$CODEX_HOME/notification-settings.json"
PLIST="$HOME/Library/LaunchAgents/com.codexnotifications.phase-watcher.plist"

if [[ ! -d "$APP_SOURCE" && -x "$ROOT/Scripts/build-app.sh" ]]; then
  "$ROOT/Scripts/build-app.sh" >/dev/null
fi
if [[ ! -d "$APP_SOURCE" ]]; then
  echo "找不到应用包 / App bundle not found: $APP_SOURCE" >&2
  exit 1
fi

mkdir -p "$HOME/Applications" "$ENGINE_DIR" "$LOG_DIR" "$CODEX_HOME"
ditto "$APP_SOURCE" "$APP_TARGET"

install -m 755 "$APP_TARGET/Contents/MacOS/CodexNotificationSettings" "$ENGINE"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  install -m 600 "$ROOT/Resources/notification-settings.default.json" "$SETTINGS_FILE"
fi

"$ENGINE" --configure-install "$CONFIG_FILE" "$SUPPORT_DIR/install-state.json" "$ENGINE"

if [[ "${CODEX_NOTIFY_EXPERIMENTAL_STAGE:-1}" == "1" ]]; then
  "$ENGINE" --write-launch-agent "$PLIST" "$ENGINE" "$LOG_DIR"
  plutil -lint "$PLIST" >/dev/null
  launchctl bootout "gui/$UID" "$PLIST" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$UID" "$PLIST"
fi

if [[ "${CODEX_NOTIFY_SKIP_OPEN:-0}" != "1" ]]; then
  open "$APP_TARGET"
fi
echo "安装完成 / Installed: $APP_TARGET"
echo "请重新打开 Codex，使 notify 配置稳定生效。 / Restart Codex to activate the notify configuration."
