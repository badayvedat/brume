import Foundation

/// Le fichier des réglages, dans Application Support, à côté de la session.
public struct SettingsFile: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static var standard: SettingsFile {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return SettingsFile(url: support.appending(path: "Brume/settings.json"))
    }

    /// Les réglages par défaut sans fichier, ou s'il est illisible.
    public func load() -> AppSettings {
        (try? Data(contentsOf: url)).flatMap(AppSettings.decoded) ?? AppSettings()
    }

    public func save(_ settings: AppSettings) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try settings.encoded().write(to: url, options: .atomic)
    }
}
