import Foundation

/// Le fichier de la session, dans Application Support : relu au lancement, réécrit en quittant.
public struct SessionFile: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static var standard: SessionFile {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return SessionFile(url: support.appending(path: "Brume/session.json"))
    }

    /// Nil sans fichier, ou s'il est illisible : Brume part alors d'une fenêtre neuve.
    public func load() -> Session? {
        (try? Data(contentsOf: url)).flatMap(Session.decoded)
    }

    /// Brume repartira d'une fenêtre neuve.
    public func delete() {
        try? FileManager.default.removeItem(at: url)
    }

    public func save(_ session: Session) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try session.encoded().write(to: url, options: .atomic)
    }
}
