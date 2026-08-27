# Compatibility / 兼容性

This matrix records the current verification boundary. “Expected” means the integration path is supported by design but still benefits from reports from different Codex versions and clients.

本表只记录当前验证边界；“设计支持”不等于已经覆盖所有 Codex 版本和客户端。

| Integration / 集成路径 | Status / 状态 | Notes / 说明 |
| --- | --- | --- |
| Codex `notify` callback | Verified / 已验证 | Native engine classification, deduplication, install/uninstall preservation, and dry-run delivery are covered by the repository test script. |
| Codex CLI | Designed support / 设计支持 | Uses the `notify` callback path; please include the CLI version when reporting an event mismatch. |
| Codex desktop app | Designed support / 设计支持 | Event availability can vary by client rollout; please include the app version and reproduction details. |
| Stage updates / 阶段成果 | Experimental / 实验性 | Read-only watcher for new rollout JSONL records under `~/.codex/sessions/`. |
| Realtime voice / 实时语音 | Experimental, off by default / 实验性，默认关闭 | Depends on local rollout fields and may need adaptation after Codex updates. |
| macOS 13+ | Targeted / 目标平台 | Release package is built as a Universal 2 macOS app; fresh installation verification is tracked in the project release history. |

When reporting a mismatch, include the macOS version, Codex version, client type (desktop or CLI), the state you expected, and redacted `Doctor.command` output. Never include API keys, passwords, session records, or full personal paths.

遇到状态识别不一致时，请附上 macOS 版本、Codex 版本、客户端类型（桌面端或 CLI）、期望状态和脱敏后的 `Doctor.command` 输出。不要上传 API key、密码、会话记录或完整个人路径。
