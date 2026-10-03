import CoreGraphics
import Foundation

/// Ce qu'un onglet retrouve au relancement : son nom, sa couleur, son icône, son groupe replié.
public struct SavedTab: Codable, Hashable, Sendable {
    public var customTitle: String?
    public var color: TabColor?
    public var icon: TabIcon?
    public var isCollapsed: Bool

    public init(customTitle: String?, color: TabColor?, icon: TabIcon?, isCollapsed: Bool) {
        self.customTitle = customTitle
        self.color = color
        self.icon = icon
        self.isCollapsed = isCollapsed
    }
}

/// Le dossier d'un terminal. Pas son historique : le shell repart à neuf, dans le même dossier.
public struct SavedPane: Codable, Hashable, Sendable {
    public var workingDirectory: String?

    public init(workingDirectory: String?) {
        self.workingDirectory = workingDirectory
    }
}

public struct SavedWindow: Codable, Hashable, Sendable {
    public var layout: WindowLayout<UUID, UUID>
    public var tabs: [UUID: SavedTab]
    public var panes: [UUID: SavedPane]
    public var frame: CGRect?

    public init(layout: WindowLayout<UUID, UUID>, tabs: [UUID: SavedTab], panes: [UUID: SavedPane], frame: CGRect?) {
        self.layout = layout
        self.tabs = tabs
        self.panes = panes
        self.frame = frame
    }
}

/// Les fenêtres ouvertes au moment de quitter, rouvertes au lancement suivant.
public struct Session: Codable, Hashable, Sendable {
    /// À relever si le format change : une session d'un format inconnu est ignorée, pas mal lue.
    public static let version = 2

    public var version = Session.version
    public var windows: [SavedWindow]

    public init(windows: [SavedWindow]) {
        self.windows = windows
    }

    public func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    /// Nil si les données sont illisibles ou d'un format inconnu : Brume part alors d'une fenêtre
    /// neuve. Une session de la version 1 est convertie.
    public static func decoded(from data: Data) -> Session? {
        let decoder = JSONDecoder()
        guard let found = try? decoder.decode(Version.self, from: data) else { return nil }
        var session = switch found.version {
        case version: try? decoder.decode(Session.self, from: data)
        case 1: (try? decoder.decode(SessionV1.self, from: data))?.converted
        default: Session?.none
        }
        session?.windows.removeAll { !$0.layout.isConsistent }
        return session
    }

    private struct Version: Decodable {
        let version: Int
    }
}

/// La version 1, d'avant les onglets à splits : des zones, chacune avec ses onglets. Chaque
/// onglet y devient un onglet sans split, dans l'ordre de lecture.
private struct SessionV1: Decodable {
    struct Window: Decodable {
        struct Layout: Decodable {
            let tree: SplitTree<UUID>
            let areas: [UUID: TabList<UUID>]
            let focusedArea: UUID
        }

        struct Tab: Decodable {
            let workingDirectory: String?
            let customTitle: String?
            let color: TabColor?
            let icon: TabIcon?
        }

        let layout: Layout
        let tabs: [UUID: Tab]
        let frame: CGRect?
    }

    let windows: [Window]

    var converted: Session {
        Session(windows: windows.compactMap { window in
            let order = window.layout.tree.panes.flatMap { window.layout.areas[$0]?.tabs ?? [] }
            guard let first = order.first else { return nil }
            var layout = order.dropFirst().reduce(WindowLayout<UUID, UUID>(tab: first, pane: first)) { $0.addingTab($1, pane: $1) }
            if let selected = window.layout.areas[window.layout.focusedArea]?.selected {
                layout = layout.selecting(selected)
            }
            var tabs: [UUID: SavedTab] = [:]
            var panes: [UUID: SavedPane] = [:]
            for id in order {
                let tab = window.tabs[id]
                tabs[id] = SavedTab(customTitle: tab?.customTitle, color: tab?.color, icon: tab?.icon, isCollapsed: false)
                panes[id] = SavedPane(workingDirectory: tab?.workingDirectory)
            }
            return SavedWindow(layout: layout, tabs: tabs, panes: panes, frame: window.frame)
        })
    }
}
