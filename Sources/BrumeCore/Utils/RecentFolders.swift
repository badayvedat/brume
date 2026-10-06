import Foundation

/// Les dossiers traversés par un terminal, le plus récent d'abord : un chemin relatif encore à
/// l'écran a pu s'afficher avant un `cd`.
public struct RecentFolders: Equatable, Sendable {
    public private(set) var all: [String] = []

    public init() {}

    public mutating func visit(_ folder: String) {
        all.removeAll { $0 == folder }
        all.insert(folder, at: 0)
        if all.count > 20 { all.removeLast() }
    }
}
