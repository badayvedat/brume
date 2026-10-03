import BrumeCore
import GhosttyTerminal
import GhosttyTheme

/// L'apparence de Brume traduite en couleurs pour le moteur.
@MainActor
enum TerminalThemes {
    static func colors(for appearance: Appearance) -> ThemeColors {
        appearance.terminalColors(palette: palette(of: appearance.commandColors))
    }

    /// Gardées : le catalogue compte près de 500 thèmes, cherchés par nom à chaque affichage.
    private static var palettes: [CommandColors: [String]] = [:]

    /// Les 16 couleurs ANSI, prises au thème de Ghostty qui porte ce nom.
    static func palette(of colors: CommandColors) -> [String] {
        if let palette = colors.ownPalette ?? palettes[colors] { return palette }
        guard let definition = colors.ghosttyName.flatMap(GhosttyThemeCatalog.theme(named:)) else {
            assertionFailure("Thème \(colors.ghosttyName ?? "") absent du catalogue de Ghostty")
            return CommandColors.brume.ownPalette!
        }
        let palette = (0 ..< 16).map { definition.palette[$0] ?? definition.foreground }
        palettes[colors] = palette
        return palette
    }

    /// Les mêmes couleurs en clair et en sombre : Brume reste sombre.
    static func engineTheme(for colors: ThemeColors) -> TerminalTheme {
        let configuration = TerminalConfiguration { builder in
            builder.withBackground(colors.background)
            builder.withForeground(colors.foreground)
            builder.withCursorColor(colors.cursor)
            builder.withSelectionBackground(colors.selection)
            builder.withSelectionForeground(colors.selectionText)
            for (index, color) in colors.palette.enumerated() {
                builder.withPalette(index, color: "#\(color)")
            }
        }
        return TerminalTheme(light: configuration, dark: configuration)
    }
}
