#!/bin/zsh
set -euo pipefail

APP_NAME="Codex Notification Settings"
APP_TARGET="$HOME/Applications/$APP_NAME.app"
SUPPORT_DIR="$HOME/Library/Application Support/Codex Notification Settings"
ENGINE_DIR="$SUPPORT_DIR/Engine"
ENGINE="$ENGINE_DIR/CodexNotificationEngine"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME/config.toml"
PLIST="$HOME/Library/LaunchAgents/com.codexnotifications.phase-watcher.plist"
TRASH_DIR="$HOME/.Trash/Codex Notification Settings Uninstall $(date +%Y%m%d-%H%M%S)"

if [[ -x "$ENGINE" ]]; then
  "$ENGINE" --configure-uninstall "$CONFIG_FILE" "$SUPPORT_DIR/install-state.json" "$ENGINE"
fi

launchctl bootout "gui/$UID" "$PLIST" >/dev/null 2>&1 || true
if [[ -f "$PLIST" ]]; then
  rm "$PLIST"
fi

mkdir -p "$TRASH_DIR"
if [[ -d "$APP_TARGET" ]]; then
  mv "$APP_TARGET" "$TRASH_DIR/"
fi
if [[ -d "$SUPPORT_DIR" ]]; then
  mv "$SUPPORT_DIR" "$TRASH_DIR/"
fi

echo "已卸载；应用与运行文件已移到：$TRASH_DIR"
echo "声音配置保留在：$CODEX_HOME/notification-settings.json"
