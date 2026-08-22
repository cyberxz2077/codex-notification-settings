# Codex Notification Settings

一个面向 macOS 的非官方 Codex 提示音设置工具。它把 Codex 的通知分成不同状态，允许分别开关、选择系统声音和调整音量；设置 App 可以随用随开，退出后后台通知仍继续工作。

<img src="Resources/app-icon-source.png" width="160" alt="Codex Notification Settings app icon">

## 功能

| 状态 | 默认声音 | 说明 |
| --- | --- | --- |
| 阶段成果 | Pop 25% | 完成一段实际工具工作后的进度更新，实验性 |
| 最终输出 | Hero 50% | 当前任务回合已经结束 |
| 需要你 | Ping 45% | 任务在等待回答或授权 |
| 任务失败 | Basso 40% | 执行未能完成 |
| 网络异常 | Submarine 30% | 连接异常或重连，实验性 |
| 实时语音 | 默认关闭 | 避免语音回答结束后再响一次系统提示音，实验性 |

- 每种状态可独立开关、选声音和调音量。
- 切换声音后自动试听，播放按钮可重复试听。
- 保留并转发安装前已有的 Codex `notify` 命令。
- 阶段监听器独立运行，设置 App 不需要常驻 Dock。
- 同一任务回合会限频去重，避免重复响铃。

## 系统要求

- macOS 13 或更高版本。
- 已安装并使用 Codex 桌面客户端或 Codex CLI。
- 下载发布包运行不需要 Python、Homebrew 或 Xcode。
- 只有从源码构建时才需要 Xcode Command Line Tools 与 Swift 6。
- `terminal-notifier` 是可选项；缺少它时声音仍可播放，只是不额外显示本工具的通知横幅。

## 安装

当前源码版：

```bash
cd codex-notification-settings
make test
./Scripts/install.sh
```

安装器会：

1. 把设置 App 安装到 `~/Applications/`。
2. 把通知引擎安装到 `~/Library/Application Support/Codex Notification Settings/`。
3. 安装由同一 Swift 可执行文件提供的原生后台引擎，不依赖 Python。
4. 增量修改 `~/.codex/config.toml` 的 `notify`，并保存原命令供转发和卸载恢复。
5. 安装实验性的阶段成果监听器。

安装后重新打开 Codex。声音配置保存在 `~/.codex/notification-settings.json`，修改即时生效。

不希望启用实验性阶段监听器时：

```bash
CODEX_NOTIFY_EXPERIMENTAL_STAGE=0 ./Scripts/install.sh
```

## 卸载

```bash
./Scripts/uninstall.sh
```

卸载器只在当前 `notify` 仍属于本工具时恢复安装前配置，不会覆盖后来由其他工具接管的配置。应用和运行文件会移动到废纸篓中的独立目录，声音设置文件默认保留。

## 构建与打包

```bash
make build
make test
./Scripts/package-release.sh 1.0.0
```

产物位于 `dist/`。构建脚本会生成同时支持 Apple Silicon 与 Intel Mac 的 Universal 2 App，并使用直接 `swiftc` 编译，以避开部分 Swift 6 工具链在 SwiftUI release 优化阶段的编译器崩溃。Swift Package 仍用于 IDE 索引和调试构建。

本地构建采用 ad-hoc 签名，只适合开发与自用。面向普通用户发布前，需要使用 Apple Developer ID 签名并完成 notarization，否则 Gatekeeper 可能阻止直接打开。

## 工作原理

- App 内的原生 Swift 引擎接收 Codex `notify` 回调，同时转发给安装前已有的通知命令。
- 同一引擎负责事件分类、并发安全去重，并调用 macOS `afplay`。
- 实验性阶段监听模式只读观察 `~/.codex/sessions/` 新增的 rollout JSONL 记录，识别完成工具工作后的阶段更新。
- SwiftUI 设置 App 与后台引擎共享同一份 JSON 配置，没有常驻播放进程。

## 隐私与限制

- 所有处理均在本机完成，不上传提示音配置或 Codex 会话内容。
- 阶段成果与实时语音识别依赖 Codex 的内部本地记录格式，Codex 更新后可能需要适配。
- 网络、失败和等待输入并非所有客户端版本都会提供结构化事件，因此可能漏报；文本分类不会把普通回答中提到的 “reconnecting” 误判为网络故障。
- 本项目不会读取 API key、密码或环境变量文件。

更完整的说明见 [隐私说明](PRIVACY.md) 和 [安全政策](SECURITY.md)。

## 免责声明

这是社区维护的非官方项目，与 OpenAI 无隶属或背书关系。Codex 是 OpenAI 的产品名称。请从 [OpenAI Codex 官方文档](https://developers.openai.com/codex/) 获取官方配置与产品信息。

## License

[MIT](LICENSE)
