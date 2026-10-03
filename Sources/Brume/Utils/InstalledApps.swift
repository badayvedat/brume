import AppKit
import BrumeCore

/// Une app du Mac qui sait ouvrir un dossier : le Finder, ou un éditeur de `Editors`.
struct InstalledApp: Identifiable {
    let id: String
    let url: URL
    let name: String
    /// Icône de l'app, à la taille d'une ligne de menu.
    let icon: NSImage

    func open(_ folder: URL) {
        NSWorkspace.shared.open([folder], withApplicationAt: url, configuration: NSWorkspace.OpenConfiguration())
    }
}

/// Cherchés une fois au lancement : une app installée ensuite apparaît au prochain lancement.
@MainActor
enum InstalledApps {
    static let finder = find("com.apple.finder")
    static let editors = Editors.bundleIdentifiers.compactMap { find($0) }

    private static func find(_ bundleIdentifier: String) -> InstalledApp? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 16, height: 16)
        return InstalledApp(id: bundleIdentifier, url: url, name: url.deletingPathExtension().lastPathComponent, icon: icon)
    }
}
