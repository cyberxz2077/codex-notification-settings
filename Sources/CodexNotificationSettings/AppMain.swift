import Foundation

@main
enum ApplicationMain {
    static func main() {
        if let exitCode = NotificationEngine.handleCommandLine(CommandLine.arguments) {
            exit(exitCode)
        }
        CodexNotificationSettingsApp.main()
    }
}
