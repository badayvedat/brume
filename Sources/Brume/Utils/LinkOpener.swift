import AppKit
import BrumeCore

/// Le ⌘-clic sur un chemin : un fichier s'ouvre dans le premier éditeur de `Editors` installé, à la
/// ligne quand elle est donnée, un dossier dans le Finder. Une URL repart au moteur, qui la passe à
/// `/usr/bin/open` comme avant.
@MainActor
enum LinkOpener {
    /// `directories` : le dossier du terminal, puis ceux qu'il a quittés, où le chemin relatif a pu
    /// s'afficher. Faux : le moteur s'en charge.
    static func open(_ text: String, from directories: [String]) -> Bool {
        if TerminalLink(text, from: nil) == .url { return false }
        for directory in directories.isEmpty ? [nil] : directories as [String?] {
            guard case let .file(path, line, column) = TerminalLink(text, from: directory) else { continue }
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
                return open(path, line: line, column: column, isDirectory: isDirectory.boolValue)
            }
        }
        // `open` d'un chemin introuvable afficherait l'alerte du Finder.
        NSSound.beep()
        return true
    }

    private static func open(_ path: String, line: Int?, column: Int?, isDirectory: Bool) -> Bool {
        let file = URL(fileURLWithPath: path)
        // Une image ou un PDF sans ligne garde son app, comme avec `open`.
        guard !isDirectory, line != nil || !isBinary(file), let editor = InstalledApps.editors.first else {
            return NSWorkspace.shared.open(file)
        }
        if let line, let url = Editors.url(opening: path, line: line, column: column, in: editor.id) {
            NSWorkspace.shared.open([url], withApplicationAt: editor.url, configuration: NSWorkspace.OpenConfiguration())
        } else {
            editor.open(file)
        }
        return true
    }

    /// Comme git : un octet nul au début du fichier, c'est du binaire.
    private static func isBinary(_ file: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: file) else { return false }
        defer { try? handle.close() }
        return (try? handle.read(upToCount: 8000))??.contains(0) == true
    }
}
