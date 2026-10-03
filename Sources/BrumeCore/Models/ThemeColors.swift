import Foundation

/// Les couleurs du terminal en hexadécimal `RRGGBB`, palette des 16 couleurs ANSI comprise.
public struct ThemeColors: Hashable, Sendable {
    public let background: String
    public let foreground: String
    public let cursor: String
    /// Le fond du texte sélectionné, et le texte dessus : sans lui, le moteur prend la couleur
    /// du fond et la sélection devient illisible.
    public let selection: String
    public let selectionText: String
    public let palette: [String]

    public init(background: String, foreground: String, cursor: String, selection: String, selectionText: String, palette: [String]) {
        self.background = background
        self.foreground = foreground
        self.cursor = cursor
        self.selection = selection
        self.selectionText = selectionText
        self.palette = palette
    }

    /// Une étape du fondu vers `target`, `progress` allant de 0 à 1, couleur par couleur.
    public func interpolated(to target: ThemeColors, at progress: Double) -> ThemeColors {
        ThemeColors(
            background: Self.mix(background, target.background, progress),
            foreground: Self.mix(foreground, target.foreground, progress),
            cursor: Self.mix(cursor, target.cursor, progress),
            selection: Self.mix(selection, target.selection, progress),
            selectionText: Self.mix(selectionText, target.selectionText, progress),
            palette: zip(palette, target.palette).map { Self.mix($0, $1, progress) }
        )
    }

    /// `from` mêlé de `to`, à la part `amount` de 0 à 1.
    public static func mix(_ from: String, _ to: String, _ amount: Double) -> String {
        let mixed = zip(Hex.channels(from), Hex.channels(to)).map { start, end -> Double in
            (Double(start) + Double(end - start) * amount) / 255
        }
        return Hex.string(mixed)
    }
}
