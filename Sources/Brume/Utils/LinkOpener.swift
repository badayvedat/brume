import AppKit
import BrumeCore

/// Le ⌘-clic sur un chemin : un fichier s'ouvre dans le premier éditeur de `Editors` installé, à la
/// ligne quand elle est donnée, un dossier dans le Finder. Une URL ou un chemin introuvable repart
/// au moteur, qui le passe à `/usr/bin/open` comme avant.
@MainActor
enum LinkOpener {
    /// Faux : le moteur s'en charge.
    static func open(_ text: String, from directory: String?) -> Bool {
        guard case let .file(path, line, column) = TerminalLink(text, from: directory) else { return false }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return false }
        let file = URL(fileURLWithPath: path)
        // Une image ou un PDF sans ligne garde son app, comme avec `open`.
        guard !isDirectory.boolValue, line != nil || !isBinary(file), let editor = InstalledApps.editors.first else {
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
