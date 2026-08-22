import AppKit
import Foundation
import SwiftUI

struct SoundState: Codable, Equatable {
    var enabled: Bool
    var sound: String
    var volume: Double
}

struct NotificationSettings: Codable, Equatable {
    var enabled: Bool
    var states: [String: SoundState]

    static let defaults = NotificationSettings(
        enabled: true,
        states: [
            "stage": SoundState(enabled: true, sound: "Pop", volume: 0.25),
            "complete": SoundState(enabled: true, sound: "Hero", volume: 0.50),
            "needs_input": SoundState(enabled: true, sound: "Ping", volume: 0.45),
            "failed": SoundState(enabled: true, sound: "Basso", volume: 0.40),
            "network": SoundState(enabled: true, sound: "Submarine", volume: 0.30),
            "voice": SoundState(enabled: false, sound: "Glass", volume: 0.20),
        ]
    )
}

struct StateMetadata: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let experimentalNote: String?

    init(
        id: String,
        title: String,
        subtitle: String,
        icon: String,
        experimentalNote: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.experimentalNote = experimentalNote
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings = NotificationSettings.defaults
    @Published private(set) var status = L10n.text("更改即时生效", "Changes take effect immediately")
    private var previewTask: Process?

    let configURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".codex/notification-settings.json")

    let sounds: [String] = {
        let directory = URL(fileURLWithPath: "/System/Library/Sounds")
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        return urls
            .filter { $0.pathExtension.lowercased() == "aiff" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }()

    init() {
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            settings = .defaults
            save(statusText: L10n.text("已创建默认配置", "Created default configuration"))
            return
        }
        do {
            let data = try Data(contentsOf: configURL)
            let decoded = try JSONDecoder().decode(NotificationSettings.self, from: data)
            settings = normalized(decoded)
            status = L10n.text("更改即时生效", "Changes take effect immediately")
        } catch {
            settings = .defaults
            status = L10n.text("配置文件无效，尚未覆盖", "Invalid configuration; the file was not overwritten")
        }
    }

    func setMasterEnabled(_ enabled: Bool) {
        settings.enabled = enabled
        save()
    }

    func state(for id: String) -> SoundState {
        settings.states[id] ?? NotificationSettings.defaults.states[id]!
    }

    func updateState(_ id: String, _ transform: (inout SoundState) -> Void) {
        var state = self.state(for: id)
        transform(&state)
        state.volume = min(1, max(0, state.volume))
        if !sounds.contains(state.sound) {
            state.sound = NotificationSettings.defaults.states[id]?.sound ?? "Pop"
        }
        settings.states[id] = state
        save()
    }

    func selectSound(_ sound: String, for id: String) {
        updateState(id) { $0.sound = sound }
        preview(id)
    }

    func reset() {
        settings = .defaults
        save(statusText: L10n.text("已恢复默认", "Restored defaults"))
    }

    func preview(_ id: String) {
        let state = state(for: id)
        let soundURL = URL(fileURLWithPath: "/System/Library/Sounds/\(state.sound).aiff")
        guard FileManager.default.fileExists(atPath: soundURL.path) else {
            status = L10n.text("声音文件不可用", "Sound file is unavailable")
            return
        }
        if let previewTask, previewTask.isRunning {
            previewTask.terminate()
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
        task.arguments = ["-v", String(format: "%.2f", state.volume), soundURL.path]
        do {
            try task.run()
            previewTask = task
            status = L10n.text("正在试听：\(state.sound)", "Previewing: \(state.sound)")
        } catch {
            status = L10n.text("试听失败", "Preview failed")
        }
    }

    func revealConfig() {
        NSWorkspace.shared.activateFileViewerSelecting([configURL])
    }

    private func normalized(_ candidate: NotificationSettings) -> NotificationSettings {
        var result = NotificationSettings.defaults
        result.enabled = candidate.enabled
        for id in result.states.keys {
            guard var state = candidate.states[id] else { continue }
            state.volume = min(1, max(0, state.volume))
            if !sounds.contains(state.sound) {
                state.sound = result.states[id]?.sound ?? "Pop"
            }
            result.states[id] = state
        }
        return result
    }

    private func save(statusText: String? = nil) {
        do {
            let directory = configURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(settings)
            try data.write(to: configURL, options: .atomic)
            status = statusText ?? L10n.text("已保存", "Saved")
        } catch {
            status = L10n.text("保存失败", "Save failed")
        }
    }
}

struct StateRow: View {
    let metadata: StateMetadata
    @ObservedObject var store: SettingsStore

    private var state: SoundState { store.state(for: metadata.id) }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: metadata.icon)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(state.enabled ? Color.accentColor : Color.secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(metadata.title)
                        .font(.system(size: 14, weight: .semibold))
                    if let experimentalNote = metadata.experimentalNote {
                        Text(L10n.text("实验性", "Experimental"))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.orange)
                            .help(experimentalNote)
                    }
                }
                Text(metadata.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 150, alignment: .leading)

            Toggle("", isOn: Binding(
                get: { state.enabled },
                set: { value in store.updateState(metadata.id) { $0.enabled = value } }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .help(state.enabled
                ? L10n.text("关闭此状态的提示音", "Disable sound for this state")
                : L10n.text("开启此状态的提示音", "Enable sound for this state"))

            Picker(L10n.text("声音", "Sound"), selection: Binding(
                get: { state.sound },
                set: { value in store.selectSound(value, for: metadata.id) }
            )) {
                ForEach(store.sounds, id: \.self) { sound in
                    Text(sound).tag(sound)
                }
            }
            .labelsHidden()
            .frame(width: 120)
            .disabled(!state.enabled)
            .help(L10n.text("选择声音；切换后自动试听", "Choose a sound; changes preview automatically"))

            Slider(value: Binding(
                get: { state.volume },
                set: { value in store.updateState(metadata.id) { $0.volume = value } }
            ), in: 0...1, step: 0.05)
            .frame(width: 130)
            .disabled(!state.enabled)
            .help(L10n.text("调整音量", "Adjust volume"))

            Text("\(Int((state.volume * 100).rounded()))%")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .trailing)

            Button {
                store.preview(metadata.id)
            } label: {
                Image(systemName: "play.fill")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderless)
            .help(L10n.text("试听 \(metadata.title)", "Preview \(metadata.title)"))
            .accessibilityLabel(L10n.text("试听 \(metadata.title)", "Preview \(metadata.title)"))
        }
        .frame(height: 54)
        .opacity(store.settings.enabled ? 1 : 0.55)
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    private var rows: [StateMetadata] { [
        StateMetadata(
            id: "stage",
            title: L10n.text("阶段成果", "Progress update"),
            subtitle: L10n.text("完成一段实际工作后的进度更新", "A progress update after meaningful work"),
            icon: "circle.dotted",
            experimentalNote: L10n.text("实验性：Codex 更新后可能需适配", "Experimental: Codex updates may require changes")
        ),
        StateMetadata(id: "complete", title: L10n.text("最终输出", "Final response"), subtitle: L10n.text("任务完成并可查看", "The task is ready to review"), icon: "checkmark.circle.fill"),
        StateMetadata(id: "needs_input", title: L10n.text("需要你", "Needs you"), subtitle: L10n.text("等待回答或授权", "Waiting for an answer or approval"), icon: "person.crop.circle.badge.questionmark"),
        StateMetadata(id: "failed", title: L10n.text("任务失败", "Task failed"), subtitle: L10n.text("执行未能完成", "The task could not be completed"), icon: "xmark.octagon.fill"),
        StateMetadata(
            id: "network",
            title: L10n.text("网络异常", "Network issue"),
            subtitle: L10n.text("断线或正在重连", "Disconnected or reconnecting"),
            icon: "wifi.exclamationmark",
            experimentalNote: L10n.text("实验性：可能漏报部分网络状态", "Experimental: some network states may be missed")
        ),
        StateMetadata(
            id: "voice",
            title: L10n.text("实时语音", "Realtime voice"),
            subtitle: L10n.text("语音回答结束", "A voice response has ended"),
            icon: "waveform",
            experimentalNote: L10n.text("实验性：内部语音状态可能变化", "Experimental: internal voice states may change")
        ),
    ] }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: store.settings.enabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("Codex 提示音", "Codex Notification Sounds"))
                        .font(.system(size: 20, weight: .bold))
                    Text(L10n.text("状态声音与音量", "Sounds and volume by state"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(L10n.text("启用提示音", "Enable sounds"), isOn: Binding(
                    get: { store.settings.enabled },
                    set: store.setMasterEnabled
                ))
                .toggleStyle(.switch)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)

            Divider()

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, metadata in
                    StateRow(metadata: metadata, store: store)
                    if index < rows.count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .padding(.horizontal, 22)

            Divider()

            HStack {
                Text(store.status)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    store.revealConfig()
                } label: {
                    Image(systemName: "folder")
                }
                .help(L10n.text("在访达中显示配置", "Show configuration in Finder"))
                .accessibilityLabel(L10n.text("在访达中显示配置", "Show configuration in Finder"))

                Button(L10n.text("恢复默认", "Restore Defaults")) {
                    store.reset()
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
        }
        .frame(width: 650)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

struct CodexNotificationSettingsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = SettingsStore()

    var body: some Scene {
        Window(L10n.text("Codex 提示音", "Codex Notification Sounds"), id: "notification-settings") {
            SettingsView(store: store)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(L10n.text("关于 Codex 提示音", "About Codex Notification Sounds")) {
                    let version = Bundle.main.object(
                        forInfoDictionaryKey: "CFBundleShortVersionString"
                    ) as? String ?? L10n.text("未知", "Unknown")
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: L10n.text("Codex 提示音", "Codex Notification Sounds"),
                        .version: version,
                    ])
                }
            }
        }
    }
}
