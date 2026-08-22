// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexNotificationSettings",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "CodexNotificationSettings",
            targets: ["CodexNotificationSettings"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "CodexNotificationSettings",
            path: "Sources/CodexNotificationSettings"
        ),
    ],
    swiftLanguageModes: [.v5]
)
