import AppKit
import BrumeCore

/// Le service du Finder « Nouvel onglet Brume ici », déclaré dans l'Info.plist par
/// `scripts/build-app.sh` : `NSMessage` y nomme `openTab`, macOS appelle `openTab:userData:error:`.
@MainActor
final class FolderService: NSObject {
    @objc func openTab(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        TerminalWorkspace.openTabs(in: OpenedFolders.paths(for: urls))
    }
}
