# Community sharing copy / 社区分享文案

These drafts are intentionally short and factual. They are ready to adapt for a forum, newsletter, or social post; they do not claim official OpenAI affiliation or unsupported compatibility.

## 中文

### 标题

让 Codex 的“完成、等待、失败”听起来不一样

### 正文

Codex 工作时经常要等编译、工具调用或人工确认。默认提示音很难直接区分状态，所以我做了一个原生 macOS 小工具：为“阶段成果、最终输出、需要你、任务失败、网络异常”分别设置声音、音量和开关。

设置 App 可以关闭，后台通知仍然工作；数据只在本机处理，不需要 Python、Homebrew 或 Xcode。当前推荐安装包是 v1.0.2：
https://github.com/cyberxz2077/codex-notification-settings/releases/tag/v1.0.2

如果你使用 Codex 桌面端或 CLI，欢迎反馈 macOS/Codex 版本和哪一种状态没有被正确区分。

## English

### Title

Make Codex completion, waiting, and failure sound different

### Body

Codex often waits on builds, tool calls, or human approval. A generic cue does not tell you which state occurred, so I built a native macOS utility that maps stage updates, final output, needs-you prompts, failures, and network issues to separate sounds, volumes, and toggles.

The settings app can quit while background notifications keep working. Everything stays local, and packaged installs do not require Python, Homebrew, or Xcode. The recommended release is v1.0.2:
https://github.com/cyberxz2077/codex-notification-settings/releases/tag/v1.0.2

If you use Codex desktop or CLI, reports with your macOS/Codex versions and the state that was not distinguished correctly are welcome.
