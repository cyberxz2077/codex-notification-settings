# Security Policy

## Reporting

请通过 GitHub Security Advisory 私下报告可能暴露本地会话内容、秘密信息或允许命令注入的问题，不要先创建公开 Issue。

报告中请包含受影响版本、复现步骤、预期行为和实际行为。项目不会要求你提供真实 API key 或完整私人会话记录。

## Scope

安全边界包括 Codex 配置的增量修改、原通知命令转发、LaunchAgent 路径渲染，以及对 `~/.codex/sessions/` 的只读处理。
