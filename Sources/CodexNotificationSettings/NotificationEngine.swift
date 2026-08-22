import Darwin
import Foundation

enum NotificationCategory: String, CaseIterable {
    case stage
    case complete
    case needsInput = "needs_input"
    case failed
    case network
    case voice

    var title: String {
        switch self {
        case .stage: L10n.text("Codex 进展", "Codex progress")
        case .complete: "Codex"
        case .needsInput: L10n.text("Codex 需要你", "Codex needs you")
        case .failed: L10n.text("Codex 未完成", "Codex task failed")
        case .network: L10n.text("Codex 网络异常", "Codex network issue")
        case .voice: L10n.text("Codex 语音", "Codex voice")
        }
    }

    var message: String {
        switch self {
        case .stage: L10n.text("阶段成果已更新", "Progress update available")
        case .complete: L10n.text("任务完成，可以查看", "Task complete and ready to review")
        case .needsInput: L10n.text("任务暂停，等待你的回答或授权", "Task paused for your answer or approval")
        case .failed: L10n.text("任务遇到问题，请检查", "The task ran into a problem")
        case .network: L10n.text("连接异常或正在重连", "Connection lost or reconnecting")
        case .voice: L10n.text("实时语音回合已结束", "Realtime voice turn ended")
        }
    }
}

enum NotificationEngine {
    private static let needsInputTypes: Set<String> = [
        "approval-requested", "approval_requested", "request-user-input",
        "request_user_input", "elicitation-request", "elicitation_request",
    ]
    private static let failedTypes: Set<String> = [
        "failed", "task-failed", "task_failed", "turn-failed", "turn_failed",
        "stream-error", "stream_error",
    ]
    private static let networkTypes: Set<String> = [
        "network-error", "network_error", "reconnecting", "connection-lost",
        "connection_lost",
    ]
    private static let workResultTypes: Set<String> = [
        "custom_tool_call_output", "function_call_output", "image_generation_end",
        "mcp_tool_call_end", "patch_apply_end", "tool_search_output", "web_search_end",
    ]

    private static var environment: [String: String] { ProcessInfo.processInfo.environment }
    private static var homeURL: URL {
        if let override = environment["CODEX_NOTIFICATION_HOME"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }
    private static var codexHome: URL {
        if let override = environment["CODEX_HOME"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return homeURL.appendingPathComponent(".codex", isDirectory: true)
    }
    private static var settingsURL: URL {
        codexHome.appendingPathComponent("notification-settings.json")
    }
    private static var stateURL: URL {
        codexHome.appendingPathComponent("notification-router-state.json")
    }
    private static var sessionsURL: URL {
        codexHome.appendingPathComponent("sessions", isDirectory: true)
    }
    private static var logDirectory: URL {
        homeURL.appendingPathComponent("Library/Logs/Codex Notification Settings", isDirectory: true)
    }

    static func handleCommandLine(_ arguments: [String]) -> Int32? {
        guard arguments.count > 1 else { return nil }
        let command = arguments[1]
        do {
            switch command {
            case "--notify":
                return runNotification(Array(arguments.dropFirst(2)))
            case "--classify":
                let event = parseEvent(Array(arguments.dropFirst(2)))
                print(classify(event).rawValue)
                return 0
            case "--phase-watch":
                PhaseWatcher().run()
                return 0
            case "--configure-install":
                guard arguments.count == 5 else { return usageError(command) }
                try configureInstall(
                    configURL: URL(fileURLWithPath: arguments[2]),
                    stateURL: URL(fileURLWithPath: arguments[3]),
                    executablePath: arguments[4]
                )
                return 0
            case "--configure-uninstall":
                guard arguments.count == 5 else { return usageError(command) }
                try configureUninstall(
                    configURL: URL(fileURLWithPath: arguments[2]),
                    stateURL: URL(fileURLWithPath: arguments[3]),
                    executablePath: arguments[4]
                )
                return 0
            case "--write-launch-agent":
                guard arguments.count == 5 else { return usageError(command) }
                try writeLaunchAgent(
                    outputURL: URL(fileURLWithPath: arguments[2]),
                    executablePath: arguments[3],
                    logDirectory: arguments[4]
                )
                return 0
            default:
                return nil
            }
        } catch {
            fputs("Codex Notification Settings: \(error)\n", stderr)
            return 1
        }
    }

    private static func usageError(_ command: String) -> Int32 {
        fputs("Invalid arguments for \(command)\n", stderr)
        return 2
    }

    private static func parseEvent(_ arguments: [String]) -> [String: Any] {
        guard !arguments.isEmpty else { return ["type": "agent-turn-complete"] }
        let raw = arguments.joined(separator: " ")
        guard let data = raw.data(using: .utf8),
              let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return ["message": raw]
        }
        return value
    }

    static func classify(_ event: [String: Any]) -> NotificationCategory {
        let override = string(event["notification-class"]).lowercased()
        if let category = NotificationCategory(rawValue: override) {
            return category
        }

        let threadID = string(event["thread-id"] ?? event["thread_id"])
        let turnID = string(event["turn-id"] ?? event["turn_id"])
        let realtimeValue = event["realtime-active"] ?? event["realtime_active"]
        let realtime = (realtimeValue as? Bool) ?? rolloutRealtimeActive(
            threadID: threadID,
            turnID: turnID
        )
        if realtime { return .voice }

        let eventType = string(event["type"] ?? "agent-turn-complete").lowercased()
        let text = eventText(event)
        if networkTypes.contains(eventType) { return .network }
        if failedTypes.contains(eventType) || containsAny(
            text, ["task failed", "turn failed", "未能完成", "任务失败"]
        ) {
            return .failed
        }
        if needsInputTypes.contains(eventType) || containsAny(
            text, ["等待你的回答", "需要你确认", "需要你的批准", "请提供以下"]
        ) {
            return .needsInput
        }
        if text.contains("codex-notify:stage") { return .stage }
        if text.contains("codex-notify:final") { return .complete }

        let phase = string(
            event["phase"] ?? event["message-phase"] ?? event["message_phase"]
        ).lowercased()
        if ["commentary", "progress", "intermediate"].contains(phase) { return .stage }
        return .complete
    }

    private static func eventText(_ event: [String: Any]) -> String {
        ["message", "last-assistant-message", "last_agent_message", "error", "reason", "status"]
            .compactMap { event[$0] }
            .map { string($0) }
            .joined(separator: " ")
            .lowercased()
    }

    private static func containsAny(_ text: String, _ markers: [String]) -> Bool {
        markers.contains { text.contains($0) }
    }

    private static func string(_ value: Any?) -> String {
        guard let value else { return "" }
        return value as? String ?? String(describing: value)
    }

    private static func loadSettings() -> NotificationSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data)
        else {
            return .defaults
        }
        return decoded
    }

    private static func runNotification(_ arguments: [String]) -> Int32 {
        let event = parseEvent(arguments)
        forwardPreviousNotification(arguments)
        let category = classify(event)
        let settings = loadSettings()
        let state = settings.states[category.rawValue]
        let enabled = settings.enabled && (state?.enabled ?? false)
        let emitted = enabled && shouldEmit(event: event, category: category)
        if emitted && environment["CODEX_NOTIFY_DRY_RUN"] != "1" {
            notify(category: category, state: state ?? NotificationSettings.defaults.states[category.rawValue]!)
        }
        appendLog(
            name: "notify.log",
            record: [
                "time": Int(Date().timeIntervalSince1970),
                "category": category.rawValue,
                "emitted": emitted,
                "thread_id": string(event["thread-id"] ?? event["thread_id"]),
                "turn_id": string(event["turn-id"] ?? event["turn_id"]),
            ]
        )
        if environment["CODEX_NOTIFY_DRY_RUN"] == "1" {
            print("{\"category\":\"\(category.rawValue)\",\"emitted\":\(emitted)}")
        }
        return 0
    }

    private static func shouldEmit(event: [String: Any], category: NotificationCategory) -> Bool {
        try? FileManager.default.createDirectory(
            at: codexHome,
            withIntermediateDirectories: true
        )
        let descriptor = open(stateURL.path, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { return true }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { return true }
        defer { flock(descriptor, LOCK_UN) }

        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        let data = (try? handle.readToEnd()) ?? Data()
        var state = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Double]) ?? [:]
        let now = Date().timeIntervalSince1970
        let threadID = string(event["thread-id"] ?? event["thread_id"])
        let turnID = string(event["turn-id"] ?? event["turn_id"])
        let key = "\(category.rawValue):\(threadID):\(turnID)"
        let cooldown: Double = category == .network ? 60 : category == .stage ? 30 : 5
        if now - (state[key] ?? 0) < cooldown { return false }
        state = state.filter { now - $0.value < 3600 }
        state[key] = now
        guard let output = try? JSONSerialization.data(withJSONObject: state) else { return true }
        do {
            try handle.truncate(atOffset: 0)
            try handle.seek(toOffset: 0)
            try handle.write(contentsOf: output)
            try handle.synchronize()
        } catch {
            return true
        }
        return true
    }

    private static func notify(category: NotificationCategory, state: SoundState) {
        let soundURL = URL(fileURLWithPath: "/System/Library/Sounds/\(state.sound).aiff")
        if FileManager.default.fileExists(atPath: soundURL.path) {
            spawn(["/usr/bin/afplay", "-v", String(format: "%.2f", state.volume), soundURL.path])
        }
        if let notifier = terminalNotifier() {
            spawn([
                notifier, "-title", category.title, "-message", category.message,
                "-group", "codex-\(category.rawValue)", "-ignoreDnD",
            ])
        }
    }

    private static func spawn(_ command: [String]) {
        guard let executable = command.first else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = Array(command.dropFirst())
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }

    private static func terminalNotifier() -> String? {
        let candidates = [
            "/opt/homebrew/bin/terminal-notifier",
            "/usr/local/bin/terminal-notifier",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func rolloutRealtimeActive(threadID: String, turnID: String) -> Bool {
        guard !threadID.isEmpty, let rollout = rolloutURL(threadID: threadID),
              let data = readTail(rollout, maximumBytes: 1_048_576),
              let text = String(data: data, encoding: .utf8)
        else {
            return false
        }
        for line in text.split(separator: "\n").reversed() {
            guard line.contains("\"type\":\"turn_context\"") || line.contains("\"type\": \"turn_context\"") else {
                continue
            }
            guard let data = line.data(using: .utf8),
                  let record = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload = record["payload"] as? [String: Any]
            else {
                continue
            }
            if !turnID.isEmpty && string(payload["turn_id"]) != turnID { continue }
            return payload["realtime_active"] as? Bool == true
        }
        return false
    }

    private static func rolloutURL(threadID: String) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: sessionsURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        for case let url as URL in enumerator {
            if url.lastPathComponent.hasSuffix("\(threadID).jsonl") { return url }
        }
        return nil
    }

    private static func readTail(_ url: URL, maximumBytes: UInt64) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let size = try? handle.seekToEnd() else { return nil }
        try? handle.seek(toOffset: size > maximumBytes ? size - maximumBytes : 0)
        return try? handle.readToEnd()
    }

    private static func appendLog(name: String, record: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: record),
              var line = String(data: data, encoding: .utf8)
        else {
            return
        }
        line += "\n"
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        let url = logDirectory.appendingPathComponent(name)
        guard let encoded = line.data(using: .utf8) else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: encoded)
            return
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: encoded)
    }

    private struct InstallState: Codable {
        var previousNotify: [String]

        enum CodingKeys: String, CodingKey {
            case previousNotify = "previous_notify"
        }
    }

    private struct NotifySpan {
        let command: [String]
        let range: NSRange
    }

    private static func findNotify(in text: String) throws -> NotifySpan? {
        let source = text as NSString
        let fullRange = NSRange(location: 0, length: source.length)
        let notifyRegex = try NSRegularExpression(pattern: "(?m)^[ \\t]*notify[ \\t]*=[ \\t]*")
        guard let match = notifyRegex.firstMatch(in: text, range: fullRange) else { return nil }
        let tableRegex = try NSRegularExpression(pattern: "(?m)^[ \\t]*\\[")
        if let table = tableRegex.firstMatch(in: text, range: fullRange), match.range.location > table.range.location {
            return nil
        }
        var arrayStart = NSMaxRange(match.range)
        while arrayStart < source.length && source.character(at: arrayStart) != 91 { arrayStart += 1 }
        guard arrayStart < source.length else {
            throw EngineError.invalidNotify(L10n.text("notify 不是数组", "notify is not an array"))
        }

        var depth = 0
        var quote: unichar = 0
        var escaped = false
        var arrayEnd = -1
        for index in arrayStart..<source.length {
            let character = source.character(at: index)
            if quote != 0 {
                if escaped {
                    escaped = false
                } else if character == 92 && quote == 34 {
                    escaped = true
                } else if character == quote {
                    quote = 0
                }
                continue
            }
            if character == 34 || character == 39 {
                quote = character
            } else if character == 91 {
                depth += 1
            } else if character == 93 {
                depth -= 1
                if depth == 0 {
                    arrayEnd = index + 1
                    break
                }
            }
        }
        guard arrayEnd > arrayStart else {
            throw EngineError.invalidNotify(L10n.text("notify 数组未闭合", "notify array is not closed"))
        }
        let command = try parseStringArray(source.substring(with: NSRange(location: arrayStart, length: arrayEnd - arrayStart)))
        var lineEnd = arrayEnd
        while lineEnd < source.length && source.character(at: lineEnd) != 10 { lineEnd += 1 }
        if lineEnd < source.length { lineEnd += 1 }
        return NotifySpan(command: command, range: NSRange(location: match.range.location, length: lineEnd - match.range.location))
    }

    private static func parseStringArray(_ raw: String) throws -> [String] {
        if let data = raw.data(using: .utf8),
           let values = try? JSONSerialization.jsonObject(with: data) as? [String]
        {
            return values
        }
        let source = raw as NSString
        var values: [String] = []
        var index = 1
        while index < source.length - 1 {
            let character = source.character(at: index)
            if character == 35 {
                while index < source.length && source.character(at: index) != 10 { index += 1 }
                continue
            }
            guard character == 34 || character == 39 else {
                index += 1
                continue
            }
            let quote = character
            index += 1
            var value = ""
            while index < source.length {
                let current = source.character(at: index)
                if current == quote {
                    index += 1
                    values.append(value)
                    break
                }
                if current == 92 && quote == 34 && index + 1 < source.length {
                    index += 1
                    let escaped = source.character(at: index)
                    switch escaped {
                    case 110: value.append("\n")
                    case 114: value.append("\r")
                    case 116: value.append("\t")
                    default: value.append(Character(UnicodeScalar(escaped)!))
                    }
                } else {
                    guard let scalar = UnicodeScalar(current) else {
                        throw EngineError.invalidNotify(L10n.text("notify 包含无效字符", "notify contains an invalid character"))
                    }
                    value.append(Character(scalar))
                }
                index += 1
            }
        }
        return values
    }

    private static func renderNotify(_ command: [String]) throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: command,
            options: [.withoutEscapingSlashes]
        )
        return "notify = \(String(decoding: data, as: UTF8.self))\n"
    }

    private static func replaceNotify(in text: String, with command: [String]?) throws -> String {
        let replacement = try command.map(renderNotify) ?? ""
        if let found = try findNotify(in: text) {
            return (text as NSString).replacingCharacters(in: found.range, with: replacement)
        }
        guard !replacement.isEmpty else { return text }
        return replacement + (text.isEmpty ? "" : "\n") + text
    }

    private static func atomicWrite(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    private static func configureInstall(
        configURL: URL,
        stateURL: URL,
        executablePath: String
    ) throws {
        let text = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
        let current = try findNotify(in: text)?.command ?? []
        let command = [executablePath, "--notify"]
        if current == command {
            print(L10n.text("Codex notify 已配置。", "Codex notify is already configured."))
            return
        }
        let state = try JSONEncoder().encode(InstallState(previousNotify: current))
        try atomicWrite(state, to: stateURL)
        let updated = try replaceNotify(in: text, with: command)
        try atomicWrite(Data(updated.utf8), to: configURL)
        print(L10n.text(
            "已配置 Codex notify，并保留原有通知命令。",
            "Configured Codex notify and preserved the previous notification command."
        ))
    }

    private static func configureUninstall(
        configURL: URL,
        stateURL: URL,
        executablePath: String
    ) throws {
        let text = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
        let command = [executablePath, "--notify"]
        guard try findNotify(in: text)?.command == command else {
            print(L10n.text(
                "当前 Codex notify 不属于本应用，未修改配置。",
                "The current Codex notify command does not belong to this app; configuration was not changed."
            ))
            return
        }
        let decodedState: InstallState?
        if let data = try? Data(contentsOf: stateURL) {
            decodedState = try? JSONDecoder().decode(InstallState.self, from: data)
        } else {
            decodedState = nil
        }
        let previous = decodedState?.previousNotify ?? []
        let updated = try replaceNotify(in: text, with: previous.isEmpty ? nil : previous)
        try atomicWrite(Data(updated.utf8), to: configURL)
        print(L10n.text(
            "已恢复安装前的 Codex notify 配置。",
            "Restored the Codex notify configuration from before installation."
        ))
    }

    private static func forwardPreviousNotification(_ eventArguments: [String]) {
        let stateURL = homeURL
            .appendingPathComponent("Library/Application Support/Codex Notification Settings/install-state.json")
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(InstallState.self, from: data),
              !state.previousNotify.isEmpty
        else {
            return
        }
        spawn(state.previousNotify + eventArguments)
    }

    private static func writeLaunchAgent(
        outputURL: URL,
        executablePath: String,
        logDirectory: String
    ) throws {
        let plist: [String: Any] = [
            "Label": "com.codexnotifications.phase-watcher",
            "ProgramArguments": [executablePath, "--phase-watch"],
            "RunAtLoad": true,
            "KeepAlive": true,
            "ProcessType": "Background",
            "StandardOutPath": "\(logDirectory)/phase-watcher.stdout.log",
            "StandardErrorPath": "\(logDirectory)/phase-watcher.stderr.log",
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try atomicWrite(data, to: outputURL)
    }

    private enum EngineError: LocalizedError {
        case invalidNotify(String)

        var errorDescription: String? {
            switch self {
            case let .invalidNotify(message): message
            }
        }
    }

    private final class PhaseWatcher {
        private var offsets: [URL: UInt64] = [:]
        private var turnIDs: [URL: String] = [:]
        private var realtime: [URL: Bool] = [:]
        private var completedWork: [URL: Bool] = [:]
        private var lastStage: [String: TimeInterval] = [:]

        func run() {
            discover(baseline: true)
            NotificationEngine.appendLog(
                name: "phase-watcher.log",
                record: ["time": Int(Date().timeIntervalSince1970), "event": "started", "files": offsets.count]
            )
            var nextDiscovery = Date.distantPast
            while true {
                let now = Date()
                if now >= nextDiscovery {
                    discover(baseline: false)
                    nextDiscovery = now.addingTimeInterval(3)
                }
                for url in offsets.keys { readAppends(url) }
                Thread.sleep(forTimeInterval: 0.75)
            }
        }

        private func discover(baseline: Bool) {
            guard let enumerator = FileManager.default.enumerator(
                at: NotificationEngine.sessionsURL,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                return
            }
            for case let url as URL in enumerator where url.lastPathComponent.hasPrefix("rollout-") && url.pathExtension == "jsonl" {
                guard offsets[url] == nil else { continue }
                let size = ((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                offsets[url] = baseline ? UInt64(size) : 0
                let context = recentTurnContext(url)
                turnIDs[url] = context.turnID
                realtime[url] = context.realtime
                completedWork[url] = false
            }
        }

        private func recentTurnContext(_ url: URL) -> (turnID: String, realtime: Bool) {
            guard let data = NotificationEngine.readTail(url, maximumBytes: 1_048_576),
                  let text = String(data: data, encoding: .utf8)
            else {
                return ("", false)
            }
            for line in text.split(separator: "\n").reversed() {
                guard line.contains("turn_context"),
                      let data = line.data(using: .utf8),
                      let record = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      record["type"] as? String == "turn_context",
                      let payload = record["payload"] as? [String: Any]
                else {
                    continue
                }
                return (
                    NotificationEngine.string(payload["turn_id"]),
                    payload["realtime_active"] as? Bool == true
                )
            }
            return ("", false)
        }

        private func readAppends(_ url: URL) {
            let offset = offsets[url] ?? 0
            guard let handle = try? FileHandle(forReadingFrom: url) else { return }
            defer { try? handle.close() }
            guard let size = try? handle.seekToEnd() else { return }
            let start = size < offset ? 0 : offset
            guard size > start else { return }
            try? handle.seek(toOffset: start)
            guard let data = try? handle.readToEnd() else { return }
            guard let newline = data.lastIndex(of: 10) else { return }
            let complete = data.prefix(through: newline)
            offsets[url] = start + UInt64(complete.count)
            for line in complete.split(separator: 10) {
                guard let record = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any] else {
                    continue
                }
                processRecord(url, record: record)
            }
        }

        private func processRecord(_ url: URL, record: [String: Any]) {
            guard let payload = record["payload"] as? [String: Any] else { return }
            if record["type"] as? String == "turn_context" {
                turnIDs[url] = NotificationEngine.string(payload["turn_id"])
                realtime[url] = payload["realtime_active"] as? Bool == true
                completedWork[url] = false
                return
            }
            guard record["type"] as? String == "response_item" else { return }
            let payloadType = NotificationEngine.string(payload["type"]).lowercased()
            if NotificationEngine.workResultTypes.contains(payloadType) {
                completedWork[url] = true
                return
            }
            guard payloadType == "message",
                  payload["role"] as? String == "assistant",
                  NotificationEngine.string(payload["phase"]).lowercased() == "commentary"
            else {
                return
            }
            let threadID = threadIDFor(url)
            let turnID = turnIDs[url] ?? ""
            if realtime[url] == true {
                logStage(threadID, turnID, emitted: false, reason: "realtime")
                return
            }
            guard completedWork[url] == true else {
                logStage(threadID, turnID, emitted: false, reason: "no_completed_work")
                return
            }
            completedWork[url] = false
            let key = "\(threadID):\(turnID)"
            let now = Date().timeIntervalSince1970
            guard now - (lastStage[key] ?? 0) >= 30 else {
                logStage(threadID, turnID, emitted: false, reason: "cooldown")
                return
            }
            let settings = NotificationEngine.loadSettings()
            let state = settings.states[NotificationCategory.stage.rawValue]
            guard settings.enabled, let state, state.enabled else {
                logStage(threadID, turnID, emitted: false, reason: "disabled")
                return
            }
            if NotificationEngine.environment["CODEX_PHASE_WATCHER_DRY_RUN"] != "1" {
                NotificationEngine.notify(category: .stage, state: state)
            }
            lastStage[key] = now
            lastStage = lastStage.filter { now - $0.value < 3600 }
            logStage(threadID, turnID, emitted: true, reason: nil)
        }

        private func threadIDFor(_ url: URL) -> String {
            let name = url.deletingPathExtension().lastPathComponent
            return name.split(separator: "-").suffix(5).joined(separator: "-")
        }

        private func logStage(_ threadID: String, _ turnID: String, emitted: Bool, reason: String?) {
            var record: [String: Any] = [
                "time": Int(Date().timeIntervalSince1970),
                "event": "stage",
                "thread_id": threadID,
                "turn_id": turnID,
                "emitted": emitted,
            ]
            if let reason { record["reason"] = reason }
            NotificationEngine.appendLog(name: "phase-watcher.log", record: record)
        }
    }
}
