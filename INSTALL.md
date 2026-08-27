# Install / 安装

## English

1. Download the recommended [v1.0.2 GitHub Release](https://github.com/cyberxz2077/codex-notification-settings/releases/tag/v1.0.2): `Codex-Notification-Settings-1.0.2-macos.zip` and its `.sha256` file.
2. Optionally verify the download:

   ```bash
   shasum -a 256 -c Codex-Notification-Settings-1.0.2-macos.zip.sha256
   ```

3. Unzip the archive and double-click `Install.command`.
4. Restart Codex, then open **Codex Notification Settings** from `~/Applications` whenever you want to change sounds.

If macOS reports that the app is damaged or cannot be verified, stop and re-download v1.0.2, then verify the SHA-256 file. Do not launch `CodexNotificationEngine` directly; it is a background component installed by `Install.command`.

To uninstall, double-click `Uninstall.command` from the same release folder. The uninstaller restores the prior Codex `notify` command when safe and moves installed runtime files to Trash.

For diagnostics, double-click `Doctor.command`.

## 中文

1. 从[推荐的 v1.0.2 GitHub Release](https://github.com/cyberxz2077/codex-notification-settings/releases/tag/v1.0.2) 下载 `Codex-Notification-Settings-1.0.2-macos.zip` 及其 `.sha256` 文件。
2. 可选：校验下载文件：

   ```bash
   shasum -a 256 -c Codex-Notification-Settings-1.0.2-macos.zip.sha256
   ```

3. 解压后双击 `Install.command`。
4. 重新打开 Codex。之后需要调整声音时，从 `~/Applications` 打开 **Codex Notification Settings**。

如果 macOS 提示应用已损坏或无法验证，请停止操作，重新下载 v1.0.2 并先校验 SHA-256。不要直接运行 `CodexNotificationEngine`，它是由 `Install.command` 安装的后台组件。

需要卸载时，双击同一发布目录中的 `Uninstall.command`。卸载器会在安全时恢复原 Codex `notify` 命令，并把应用和运行文件移到废纸篓。

需要诊断安装状态时，双击 `Doctor.command`。
