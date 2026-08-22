#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP="$ROOT/dist/Codex Notification Settings.app"
BIN="$APP/Contents/MacOS/CodexNotificationSettings"

"$ROOT/Scripts/build-app.sh" >/dev/null

assert_equal() {
  if [[ "$1" != "$2" ]]; then
    echo "Expected '$2', got '$1'" >&2
    exit 1
  fi
}

assert_equal "$($BIN --classify '{"type":"reconnecting","realtime_active":false}')" "network"
assert_equal "$($BIN --classify '{"type":"agent-turn-complete","last-assistant-message":"fixed reconnecting","realtime_active":false}')" "complete"
assert_equal "$($BIN --classify '{"type":"agent-turn-complete","realtime_active":true}')" "voice"

TEST_HOME=$(mktemp -d /tmp/codex-notification-engine.XXXXXX)
TEST_CODEX="$TEST_HOME/.codex"
CONFIG="$TEST_CODEX/config.toml"
STATE="$TEST_HOME/install-state.json"
mkdir -p "$TEST_CODEX/sessions/2026/08/22"

cat > "$CONFIG" <<'EOF'
model = "gpt-5"
notify = [
  "/usr/bin/old-notifier",
  "turn-ended",
]

[tui]
notifications = true
EOF

"$BIN" --configure-install "$CONFIG" "$STATE" "$BIN" >/dev/null
grep -Fq "$BIN" "$CONFIG"
assert_equal "$(plutil -extract previous_notify.0 raw "$STATE")" "/usr/bin/old-notifier"
"$BIN" --configure-uninstall "$CONFIG" "$STATE" "$BIN" >/dev/null
grep -Fq '/usr/bin/old-notifier' "$CONFIG"
grep -Fq 'notifications = true' "$CONFIG"

PLIST="$TEST_HOME/phase-watcher.plist"
"$BIN" --write-launch-agent "$PLIST" "$BIN" "$TEST_HOME/logs"
plutil -lint "$PLIST" >/dev/null

EVENT='{"type":"agent-turn-complete","thread_id":"test","turn_id":"1","realtime_active":false}'
FIRST=$(CODEX_NOTIFICATION_HOME="$TEST_HOME" CODEX_HOME="$TEST_CODEX" CODEX_NOTIFY_DRY_RUN=1 "$BIN" --notify "$EVENT")
SECOND=$(CODEX_NOTIFICATION_HOME="$TEST_HOME" CODEX_HOME="$TEST_CODEX" CODEX_NOTIFY_DRY_RUN=1 "$BIN" --notify "$EVENT")
[[ "$FIRST" == *'"emitted":true'* ]]
[[ "$SECOND" == *'"emitted":false'* ]]

THREAD_ID="019e2b20-7ed0-7773-918e-89442670b398"
ROLLOUT="$TEST_CODEX/sessions/2026/08/22/rollout-$THREAD_ID.jsonl"
: > "$ROLLOUT"
CODEX_NOTIFICATION_HOME="$TEST_HOME" \
CODEX_HOME="$TEST_CODEX" \
CODEX_PHASE_WATCHER_DRY_RUN=1 \
  "$BIN" --phase-watch &
WATCHER_PID=$!
sleep 1
cat >> "$ROLLOUT" <<'EOF'
{"type":"turn_context","payload":{"turn_id":"turn-1","realtime_active":false}}
{"type":"response_item","payload":{"type":"function_call_output"}}
{"type":"response_item","payload":{"type":"message","role":"assistant","phase":"commentary"}}
EOF
sleep 2
kill "$WATCHER_PID"
wait "$WATCHER_PID" 2>/dev/null || true
grep -Fq '"event":"stage"' "$TEST_HOME/Library/Logs/Codex Notification Settings/phase-watcher.log"
grep -Fq '"emitted":true' "$TEST_HOME/Library/Logs/Codex Notification Settings/phase-watcher.log"

echo "Native engine tests passed."
