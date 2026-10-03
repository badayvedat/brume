import AppKit
import BrumeCore

/// Le style de la fenêtre tel qu'il est affiché : un changement de réglage y glisse en fondu,
/// le voile et le flou ensemble.
@MainActor @Observable
final class TranslucencyTransition {
    private(set) var shown: Translucency
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored nonisolated(unsafe) private var timer: Timer?

    private static let duration: TimeInterval = 0.25

    init(_ translucency: Translucency) {
        shown = translucency
    }

    deinit {
        timer?.invalidate()
    }

    func attach(to window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        show(shown)
    }

    func animate(to target: Translucency) {
        timer?.invalidate()
        let start = shown
        let startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.step(from: start, to: target, since: startDate) }
        }
    }

    private func step(from start: Translucency, to target: Translucency, since startDate: Date) {
        let progress = min(Date().timeIntervalSince(startDate) / Self.duration, 1)
        // Le fondu passe par des étapes transparentes : la fenêtre ne s'opacifie qu'à la fin,
        // quand le voile couvre déjà tout. Rien ne saute, ni à l'aller ni au retour.
        show(start.interpolated(to: target, at: Self.easeInOut(progress)))
        if progress == 1 { timer?.invalidate() }
    }

    private func show(_ translucency: Translucency) {
        shown = translucency
        TerminalWorkspace.applyToEngine(translucency)
        if let window {
            WindowTranslucency.apply(translucency, to: window)
        }
    }

    private static func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}
