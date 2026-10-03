import CoreGraphics
import Foundation

/// Ce qu'un onglet retrouve au relancement : son dossier, son nom, sa couleur.
/// Pas l'historique du terminal : le shell repart à neuf, dans le même dossier.
public struct SavedTab: Codable, Hashable, Sendable {
    public var workingDirectory: String?
    public var customTitle: String?
    public var color: TabColor?

    public init(workingDirectory: String?, customTitle: String?, color: TabColor?) {
        self.workingDirectory = workingDirectory
        self.customTitle = customTitle
        self.color = color
    }
}

public struct SavedWindow: Codable, Hashable, Sendable {
    public var layout: WindowLayout<UUID, UUID>
    public var tabs: [UUID: SavedTab]
    public var frame: CGRect?

    public init(layout: WindowLayout<UUID, UUID>, tabs: [UUID: SavedTab], frame: CGRect?) {
        self.layout = layout
        self.tabs = tabs
        self.frame = frame
    }
}

/// Les fenêtres ouvertes au moment de quitter, rouvertes au lancement suivant.
public struct Session: Codable, Hashable, Sendable {
    /// À relever si le format change : une session d'un autre format est ignorée, pas mal lue.
    public static let version = 1

    public var version = Session.version
    public var windows: [SavedWindow]

    public init(windows: [SavedWindow]) {
        self.windows = windows
    }

    public func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    /// Nil si les données sont illisibles ou d'un autre format : Brume part alors d'une fenêtre neuve.
    public static func decoded(from data: Data) -> Session? {
        guard let session = try? JSONDecoder().decode(Session.self, from: data), session.version == version else { return nil }
        return session
    }
}
