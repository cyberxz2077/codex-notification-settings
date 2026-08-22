# 隐私说明

Codex Notification Settings 是本地工具，不包含遥测、账户系统或网络上传功能。

## 本地读取

- `~/.codex/config.toml`：安装和恢复 `notify` 命令。
- `~/.codex/sessions/`：实验性阶段监听器只读观察新增记录，用于识别阶段进度和实时语音状态。
- `/System/Library/Sounds/`：列出并播放 macOS 系统声音。

## 本地写入

- `~/.codex/notification-settings.json`：声音与音量设置。
- `~/.codex/notification-router-state.json`：短期通知去重状态。
- `~/Library/Application Support/Codex Notification Settings/`：原生后台引擎与安装前通知命令。
- `~/Library/Logs/Codex Notification Settings/`：不含对话正文的状态日志。

本项目不会读取或记录 API key、密码、Cookie 或 `.env` 文件。
