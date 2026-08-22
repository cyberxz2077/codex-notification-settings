import Foundation

enum L10n {
    static let usesChinese: Bool = {
        guard let language = Locale.preferredLanguages.first?.lowercased() else {
            return false
        }
        return language.hasPrefix("zh")
    }()

    static func text(_ chinese: String, _ english: String) -> String {
        usesChinese ? chinese : english
    }
}
