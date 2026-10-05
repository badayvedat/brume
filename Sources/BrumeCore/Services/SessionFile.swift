import Foundation

/// Le fichier de la session, dans Application Support : relu au lancement, réécrit après chaque
/// changement et en quittant.
public struct SessionFile: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static var standard: SessionFile {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return SessionFile(url: support.appending(path: "Brume/session.json"))
    }

    /// La copie d'un fichier refusé, en tout ou en partie, avant que Brume ne le réécrive.
    public var backupURL: URL {
        url.appendingPathExtension("bak")
    }

    /// Nil sans fichier, ou s'il est illisible : Brume part alors d'une fenêtre neuve.
    public func load() -> Session? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let (session, isComplete) = Session.decoded(from: data)
        if !isComplete { try? data.write(to: backupURL, options: .atomic) }
        return session
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
