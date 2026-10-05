import CoreGraphics
import Foundation

/// Ce qu'un onglet retrouve au relancement : son nom, sa couleur, son icône ; divisé, son numéro
/// de groupe et s'il était replié.
public struct SavedTab: Codable, Hashable, Sendable {
    public var customTitle: String?
    public var color: TabColor?
    public var icon: TabIcon?
    public var isCollapsed: Bool
    public var groupNumber: Int?

    public init(label: TabLabel?, isCollapsed: Bool, groupNumber: Int?) {
        customTitle = label?.title
        color = label?.color
        icon = label?.icon
        self.isCollapsed = isCollapsed
        self.groupNumber = groupNumber
    }

    public var label: TabLabel {
        TabLabel(title: customTitle, color: color, icon: icon)
    }
}

/// Le dossier d'un terminal, et son nom dans un groupe. Pas son historique : le shell repart à
/// neuf, dans le même dossier.
public struct SavedPane: Codable, Hashable, Sendable {
    public var workingDirectory: String?
    public var label: TabLabel?

    public init(workingDirectory: String?, label: TabLabel?) {
        self.workingDirectory = workingDirectory
        self.label = label
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

    /// Chaque fenêtre relue à part : une valeur illisible (retour à une version précédente, champ
    /// ajouté) ne fait perdre que la sienne. Nil si tout est illisible ou d'un format inconnu ; la
    /// version 1 est convertie. `isComplete` est faux dès que quelque chose est laissé de côté.
    public static func decoded(from data: Data) -> (session: Session?, isComplete: Bool) {
        let decoder = JSONDecoder()
        guard let found = try? decoder.decode(Version.self, from: data) else { return (nil, false) }
        let windows: [SavedWindow?]? = switch found.version {
        case version: (try? decoder.decode(Windows<SavedWindow>.self, from: data))?.windows.map(\.value)
        case 1: (try? decoder.decode(Windows<SessionV1.Window>.self, from: data))?.windows.map { $0.value?.converted }
        default: nil
        }
        guard let windows else { return (nil, false) }
        let kept = windows.compactMap { $0 }.filter(\.layout.isConsistent)
        return (Session(windows: kept), kept.count == windows.count)
    }

    private struct Version: Decodable {
        let version: Int
    }

    private struct Windows<Window: Decodable>: Decodable {
        let windows: [Readable<Window>]
    }

    /// Ne lève jamais : la fenêtre suivante du tableau est relue quand même.
    private struct Readable<Value: Decodable>: Decodable {
        let value: Value?

        init(from decoder: any Decoder) throws {
            value = try? decoder.singleValueContainer().decode(Value.self)
        }
    }
}

/// La version 1, d'avant les onglets à splits : des zones, chacune avec ses onglets. Chaque
/// onglet y devient un onglet sans split, dans l'ordre de lecture.
private enum SessionV1 {
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

        var converted: SavedWindow? {
            let order = layout.tree.panes.flatMap { layout.areas[$0]?.tabs ?? [] }
            guard let first = order.first else { return nil }
            var newLayout = order.dropFirst().reduce(WindowLayout<UUID, UUID>(tab: first, pane: first)) { $0.addingTab($1, pane: $1) }
            if let selected = layout.areas[layout.focusedArea]?.selected {
                newLayout = newLayout.selecting(selected)
            }
            var savedTabs: [UUID: SavedTab] = [:]
            var panes: [UUID: SavedPane] = [:]
            for id in order {
                let tab = tabs[id]
                savedTabs[id] = SavedTab(label: TabLabel(title: tab?.customTitle, color: tab?.color, icon: tab?.icon), isCollapsed: false, groupNumber: nil)
                panes[id] = SavedPane(workingDirectory: tab?.workingDirectory, label: nil)
            }
            return SavedWindow(layout: newLayout, tabs: savedTabs, panes: panes, frame: frame)
        }
    }
}
