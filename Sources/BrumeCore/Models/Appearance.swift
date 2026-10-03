import Foundation

/// L'apparence de Brume : le verre et son dosage, la couleur et sa force dans le fond, et la
/// coloration des commandes.
public struct Appearance: Codable, Hashable, Sendable {
    public var isGlass = true
    public var glassOpacity = Strength.medium
    public var glassBlur = Strength.medium
    public var accent = Accent.brume
    public var tint = Strength.medium
    public var commandColors = CommandColors.brume

    public init() {}

    /// Un réglage absent ou illisible garde sa valeur par défaut.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func read<T: Decodable>(_ key: CodingKeys, _ value: inout T) {
            if let decoded = try? container.decode(T.self, forKey: key) { value = decoded }
        }
        read(.isGlass, &isGlass)
        read(.glassOpacity, &glassOpacity)
        read(.glassBlur, &glassBlur)
        read(.accent, &accent)
        read(.tint, &tint)
        read(.commandColors, &commandColors)
        // Avant les crans, l'opacité et le flou étaient des nombres : on garde le cran le plus proche.
        if let old = try? container.decode(Double.self, forKey: .glassOpacity) {
            glassOpacity = .closest(to: old) { $0.veilOpacity }
        }
        if let old = try? container.decode(Double.self, forKey: .glassBlur) {
            glassBlur = .closest(to: old) { Double($0.blurRadius) }
        }
    }

    public var translucency: Translucency {
        isGlass ? Translucency(opacity: glassOpacity.veilOpacity, blur: glassBlur.blurRadius) : .opaque
    }

    /// Les couleurs du terminal sauf la palette : un fond sombre à la teinte de l'accent, et une
    /// sélection mêlée d'accent.
    public func terminalColors(palette: [String]) -> ThemeColors {
        let hue = HSL(hex: accent.hex).hue
        let saturation = accent.isNeutral ? 0 : tint.saturation
        let background = HSL(hue: hue, saturation: saturation, lightness: accent.isNeutral ? 0.06 : 0.11).hex
        let foreground = HSL(hue: hue, saturation: saturation * 0.25, lightness: 0.9).hex
        return ThemeColors(
            background: background,
            foreground: foreground,
            cursor: accent.hex,
            selection: ThemeColors.mix(background, accent.hex, accent.isNeutral ? 0.18 : 0.32),
            selectionText: "f8fafc",
            palette: palette
        )
    }
}

/// Trois crans plutôt qu'un curseur : assez pour changer d'ambiance sans se perdre.
public enum Strength: String, CaseIterable, Codable, Sendable {
    case low, medium, high

    /// La part de la teinte de l'accent dans le fond.
    public var saturation: Double {
        switch self {
        case .low: 0.15
        case .medium: 0.3
        case .high: 0.5
        }
    }

    /// En verre, la part de la couleur du fond posée sur le bureau.
    public var veilOpacity: Double {
        switch self {
        case .low: 0.6
        case .medium: 0.8
        case .high: 0.9
        }
    }

    /// Le rayon du flou du bureau, en points.
    public var blurRadius: Int {
        switch self {
        case .low: 16
        case .medium: 32
        case .high: 64
        }
    }

    static func closest(to value: Double, by measure: (Strength) -> Double) -> Strength {
        allCases.min { abs(measure($0) - value) < abs(measure($1) - value) }!
    }
}

/// Une couleur en teinte (0 à 360), saturation et luminosité (0 à 1).
public struct HSL: Hashable, Sendable {
    public var hue: Double
    public var saturation: Double
    public var lightness: Double

    public init(hue: Double, saturation: Double, lightness: Double) {
        self.hue = hue
        self.saturation = saturation
        self.lightness = lightness
    }

    /// Depuis `RRGGBB`.
    public init(hex: String) {
        let channels = Hex.channels(hex).map { Double($0) / 255 }
        let r = channels[0], g = channels[1], b = channels[2]
        let high = max(r, g, b), low = min(r, g, b), delta = high - low
        lightness = (high + low) / 2
        saturation = delta == 0 ? 0 : delta / (1 - abs(2 * lightness - 1))
        let section: Double = if delta == 0 { 0 } else if high == r { ((g - b) / delta).truncatingRemainder(dividingBy: 6) } else if high == g { (b - r) / delta + 2 } else { (r - g) / delta + 4 }
        hue = (section * 60 + 360).truncatingRemainder(dividingBy: 360)
    }

    public var hex: String {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let section = hue.truncatingRemainder(dividingBy: 360) / 60
        let x = chroma * (1 - abs(section.truncatingRemainder(dividingBy: 2) - 1))
        let (r, g, b): (Double, Double, Double) = switch Int(section) {
        case 0: (chroma, x, 0)
        case 1: (x, chroma, 0)
        case 2: (0, chroma, x)
        case 3: (0, x, chroma)
        case 4: (x, 0, chroma)
        default: (chroma, 0, x)
        }
        let m = lightness - chroma / 2
        return Hex.string([r + m, g + m, b + m])
    }
}
