import Foundation

/// La config fastfetch et le visuel de l'écran de démarrage, dans Application Support à côté des
/// réglages. Le shell les lit à chaque nouveau terminal.
public struct WelcomeFiles: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// Écrit une config par version de la page (`WelcomeBuilder.variants`) et rend leur liste, de
    /// la version choisie à la plus petite. Vide quand il n'y a rien à afficher.
    public func save(_ welcome: Welcome, accent: Accent, language: Language) throws -> [URL] {
        var written: [URL] = []
        defer { removeFiles(except: written) }
        guard welcome.isEnabled, !welcome.isEmpty else { return [] }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try WelcomeBuilder.variants(for: welcome).enumerated().map { index, variant in
            let logo = directory.appending(path: "welcome-logo-\(variant.visualSize?.rawValue ?? "none").txt")
            if let size = variant.visualSize, let drawn = WelcomeBuilder.logo(for: welcome.visual, size: size, accent: accent) {
                try write(drawn.text, to: logo)
                written.append(logo)
            }
            let config = directory.appending(path: "welcome-\(index).jsonc")
            try write(WelcomeBuilder.config(for: welcome, variant: variant, accent: accent, language: language, logoPath: logo.path), to: config)
            written.append(config)
            return config
        }
    }

    /// Les versions en trop d'un réglage précédent, et les fichiers d'anciennes versions de Brume.
    private func removeFiles(except kept: [URL]) {
        let names = Set(kept.map(\.lastPathComponent))
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in files where name.hasPrefix("welcome") && !names.contains(name) {
            try? FileManager.default.removeItem(at: directory.appending(path: name))
        }
    }

    /// Un fichier inchangé n'est pas réécrit : la pastille d'accent change plusieurs fois par seconde.
    private func write(_ text: String, to url: URL) throws {
        let data = Data(text.utf8)
        guard (try? Data(contentsOf: url)) != data else { return }
        try data.write(to: url, options: .atomic)
    }
}
