# Install / 安装

## English

1. Download `Codex-Notification-Settings-<version>-macos.zip` and its `.sha256` file from the matching GitHub Release.
2. Optionally verify the download:

   ```bash
   shasum -a 256 -c Codex-Notification-Settings-<version>-macos.zip.sha256
   ```

3. Unzip the archive and double-click `Install.command`.
4. Restart Codex, then open **Codex Notification Settings** from `~/Applications` whenever you want to change sounds.

To uninstall, double-click `Uninstall.command` from the same release folder. The uninstaller restores the prior Codex `notify` command when safe and moves installed runtime files to Trash.

For diagnostics, double-click `Doctor.command`.

## 中文

1. 从对应的 GitHub Release 下载 `Codex-Notification-Settings-<version>-macos.zip` 及其 `.sha256` 文件。
2. 可选：校验下载文件：

   ```bash
   shasum -a 256 -c Codex-Notification-Settings-<version>-macos.zip.sha256
   ```

3. 解压后双击 `Install.command`。
4. 重新打开 Codex。之后需要调整声音时，从 `~/Applications` 打开 **Codex Notification Settings**。

需要卸载时，双击同一发布目录中的 `Uninstall.command`。卸载器会在安全时恢复原 Codex `notify` 命令，并把应用和运行文件移到废纸篓。

需要诊断安装状态时，双击 `Doctor.command`。
