/// La police des terminaux. Sans famille choisie, celle de Ghostty (JetBrains Mono, embarquée).
public struct TerminalFont: Codable, Hashable, Sendable {
    public var family: String?
    public var size: Double

    public static let sizeRange = 10.0 ... 24.0
    public static let standard = TerminalFont(family: nil, size: 13)

    /// Celle du moteur quand aucune famille n'est choisie. Aussi embarquée pour l'aperçu des réglages.
    public static let defaultFamily = "JetBrains Mono"

    /// Embarquées dans l'app (`Resources/Fonts`, licences libres) : présentes sur tous les Mac.
    public static let bundled = [
        "Cascadia Code", "Fira Code", "Geist Mono", "IBM Plex Mono", "Inconsolata",
        "Roboto Mono", "Source Code Pro", "Space Mono", "Ubuntu Mono",
    ]

    /// Livrées avec macOS.
    public static let system = ["Menlo", "Monaco"]

    public init(family: String?, size: Double) {
        self.family = family
        self.size = min(max(size, Self.sizeRange.lowerBound), Self.sizeRange.upperBound)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(family: container.decodeIfPresent(String.self, forKey: .family), size: container.decode(Double.self, forKey: .size))
    }
}
