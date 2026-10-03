/// La fenêtre posée sur le bureau : la couleur du terminal en voile, le bureau flouté dessous.
public struct Translucency: Codable, Hashable, Sendable {
    /// Part de la couleur du terminal dans le voile. 1 : fenêtre opaque.
    public var opacity: Double {
        didSet { opacity = Self.clamped(opacity, to: Self.opacityRange) }
    }

    /// Rayon du flou du bureau, en points. 0 : bureau net.
    public var blur: Int {
        didSet { blur = Self.clamped(blur, to: Self.blurRange) }
    }

    /// En dessous, le texte ne se lit plus sur un bureau chargé.
    public static let opacityRange = 0.3 ... 1.0
    public static let blurRange = 0 ... 64

    public init(opacity: Double, blur: Int) {
        self.opacity = Self.clamped(opacity, to: Self.opacityRange)
        self.blur = Self.clamped(blur, to: Self.blurRange)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(opacity: try container.decode(Double.self, forKey: .opacity), blur: try container.decode(Int.self, forKey: .blur))
    }

    public var isTranslucent: Bool {
        opacity < 1
    }

    private static func clamped<T: Comparable>(_ value: T, to range: ClosedRange<T>) -> T {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

/// Les styles prêts à choisir. Un réglage fin hors preset n'en sélectionne aucun.
public enum TranslucencyPreset: String, CaseIterable, Sendable {
    case normal, glass

    public var translucency: Translucency {
        switch self {
        case .normal: Translucency(opacity: 1, blur: 0)
        case .glass: Translucency(opacity: 0.72, blur: 24)
        }
    }

    public init?(matching translucency: Translucency) {
        guard let preset = Self.allCases.first(where: { $0.translucency == translucency }) else { return nil }
        self = preset
    }
}
