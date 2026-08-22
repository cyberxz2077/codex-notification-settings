#!/bin/zsh
set -u

APP="$HOME/Applications/Codex Notification Settings.app"
SUPPORT_DIR="$HOME/Library/Application Support/Codex Notification Settings/Engine"
PLIST="$HOME/Library/LaunchAgents/com.codexnotifications.phase-watcher.plist"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

echo "Codex Notification Settings diagnostics"
echo "macOS: $(sw_vers -productVersion) ($(uname -m))"
echo "Codex config: $CODEX_HOME/config.toml"
[[ -d "$APP" ]] && echo "App: installed" || echo "App: missing"
[[ -x "$SUPPORT_DIR/CodexNotificationEngine" ]] && echo "Engine: installed" || echo "Engine: missing"
[[ -f "$CODEX_HOME/notification-settings.json" ]] && echo "Settings: present" || echo "Settings: missing"
if [[ -f "$PLIST" ]]; then
  echo "Experimental stage watcher: configured"
  launchctl print "gui/$UID/com.codexnotifications.phase-watcher" >/dev/null 2>&1 \
    && echo "Experimental stage watcher: running" \
    || echo "Experimental stage watcher: stopped"
else
  echo "Experimental stage watcher: not configured"
  echo "Experimental stage watcher: not installed"
fi
command -v terminal-notifier >/dev/null 2>&1 \
  && echo "Banner helper: $(command -v terminal-notifier)" \
  || echo "Banner helper: not installed (sounds still work)"
