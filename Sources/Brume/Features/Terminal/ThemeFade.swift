import BrumeCore
import Foundation

/// Change les couleurs du terminal en fondu : toutes glissent ensemble vers les nouvelles. Le
/// moteur est commun à toutes les fenêtres, le fondu aussi.
@MainActor
enum ThemeFade {
    private static var shown: ThemeColors?
    private static var target: ThemeColors?
    private static var timer: Timer?
    private static let duration: TimeInterval = 0.25

    /// Les couleurs de départ, sans fondu.
    static func start(with colors: ThemeColors) {
        target = colors
        shown = colors
        TerminalWorkspace.applyEngineTheme(TerminalThemes.engineTheme(for: colors))
    }

    /// Chaque fenêtre le demande : seul le premier appel lance le fondu.
    static func run(to colors: ThemeColors) {
        guard colors != target, let from = shown else { return }
        target = colors
        timer?.invalidate()
        let startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in
            MainActor.assumeIsolated { step(from: from, to: colors, since: startDate) }
        }
    }

    private static func step(from: ThemeColors, to: ThemeColors, since startDate: Date) {
        let progress = min(Date().timeIntervalSince(startDate) / duration, 1)
        let colors = from.interpolated(to: to, at: Easing.easeInOut(progress))
        shown = colors
        TerminalWorkspace.applyEngineTheme(TerminalThemes.engineTheme(for: colors))
        if progress == 1 { timer?.invalidate() }
    }
}
