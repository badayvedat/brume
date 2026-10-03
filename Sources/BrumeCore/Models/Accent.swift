/// La couleur de Brume, en pastilles comme dans Monocode : le fond en prend la teinte, l'accent
/// (onglets, curseur, sélection, interrupteurs) la couleur pleine.
public enum Accent: String, CaseIterable, Codable, Sendable {
    /// Le bleu-gris de Brume.
    case brume
    /// Un fond presque noir sans teinte, et un accent blanc.
    case black
    case blue, violet, pink, red, orange, yellow, green, teal

    /// La couleur des onglets, du curseur et de la sélection, en `RRGGBB`.
    public var hex: String {
        switch self {
        case .brume: "8b9dc3"
        case .black: "ebebeb"
        case .blue: "4da3f5"
        case .violet: "8b5cf6"
        case .pink: "ec4899"
        case .red: "ef4444"
        case .orange: "f97316"
        case .yellow: "eab308"
        case .green: "10b981"
        case .teal: "14b8a6"
        }
    }

    /// Celle de la pastille : le noir s'y montre noir, pas en blanc.
    public var swatchHex: String {
        self == .black ? "0d0d0d" : hex
    }

    public var isNeutral: Bool {
        self == .black
    }
}
