import AppKit
import BrumeCore

/// Le service du Finder « Nouvel onglet Brume ici », déclaré dans l'Info.plist par
/// `scripts/build-app.sh` : `NSMessage` y nomme `openTab`, macOS appelle `openTab:userData:error:`.
@MainActor
final class FolderService: NSObject {
    @objc func openTab(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        var urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        // Un chemin sélectionné dans un texte arrive en texte, pas en fichier.
        if urls.isEmpty, let text = pasteboard.string(forType: .string) {
            urls = [URL(fileURLWithPath: (text.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).expandingTildeInPath)]
        }
        TerminalWorkspace.openTabs(in: OpenedFolders.paths(for: urls))
    }
}
