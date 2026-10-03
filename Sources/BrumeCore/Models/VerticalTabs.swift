/// Les onglets listés dans une barre latérale à gauche, comme les onglets verticaux des
/// navigateurs, plutôt qu'en haut de chaque zone.
public struct VerticalTabs: Codable, Hashable, Sendable {
    public var isOn: Bool
    /// La largeur de la barre latérale, en points.
    public var width: Double

    public static let widthRange = 160.0 ... 360.0
    public static let standardWidth = 200.0

    public init(isOn: Bool = false, width: Double = standardWidth) {
        self.isOn = isOn
        self.width = min(max(width, Self.widthRange.lowerBound), Self.widthRange.upperBound)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            isOn: container.decodeIfPresent(Bool.self, forKey: .isOn) ?? false,
            width: container.decodeIfPresent(Double.self, forKey: .width) ?? Self.standardWidth
        )
    }
}
