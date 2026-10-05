import Foundation

/// Un lien ⌘-cliqué dans un terminal, tel que le moteur le repère : une URL, ou un chemin suivi de
/// la ligne et de la colonne des messages d'erreur (`src/App.vue:42:5` de Vite, TypeScript, ESLint).
public enum TerminalLink: Equatable, Sendable {
    /// Avec un schéma (`https:`, `mailto:`...).
    case url
    /// Le chemin absolu, résolu depuis le dossier du terminal.
    case file(path: String, line: Int?, column: Int?)

    /// `directory` : le dossier du terminal. Sans lui, un chemin relatif ne se résout pas : nil.
    public init?(_ text: String, from directory: String?, home: String = NSHomeDirectory()) {
        let text = text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        // `Makefile:12` n'est pas un schéma : un chiffre suit les deux-points.
        if text.prefixMatch(of: /[A-Za-z][A-Za-z0-9+.\-]*:(?!\d)/) != nil {
            self = .url
            return
        }
        var path = text
        var line: Int?
        var column: Int?
        if let position = text.wholeMatch(of: /(.+?):(\d+)(?::(\d+))?:?/) {
            path = String(position.1)
            line = Int(position.2)
            column = position.3.flatMap { Int($0) }
        }
        if path == "~" || path.hasPrefix("~/") {
            path = home + path.dropFirst()
        } else if !path.hasPrefix("/") {
            guard let directory else { return nil }
            path = directory + "/" + path
        }
        self = .file(path: URL(fileURLWithPath: path).standardizedFileURL.path, line: line, column: column)
    }
}
