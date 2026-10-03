import AppKit
import SwiftUI

/// La barre de titre native, vide, sous la barre d'onglets : la place que prennent
/// les boutons rouge, jaune, vert, et le plein écran qui les cache.
@MainActor @Observable
final class WindowTitlebar {
    private(set) var buttonsWidth: CGFloat = 0
    /// Depuis le haut de la fenêtre : la barre se centre sur les boutons plutôt que de les déplacer.
    private(set) var buttonsCenterY: CGFloat = 20
    private(set) var isFullScreen = false
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func attach(to window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        // La barre de 40 de Monocode, boutons centrés dedans : une barre d'outils vide et compacte
        // donne cette hauteur à la barre de titre native, sans déplacer les boutons à la main.
        let toolbar = NSToolbar(identifier: "brume")
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .unifiedCompact
        update()
        for name in [NSWindow.didEnterFullScreenNotification, NSWindow.didExitFullScreenNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.update() }
            })
        }
    }

    private func update() {
        guard let window else { return }
        isFullScreen = window.styleMask.contains(.fullScreen)
        // En plein écran, les boutons vivent ailleurs : garder la mesure faite en fenêtre.
        guard !isFullScreen, let zoom = window.standardWindowButton(.zoomButton) else { return }
        buttonsWidth = zoom.frame.maxX
        buttonsCenterY = window.frame.height - zoom.convert(CGPoint(x: zoom.bounds.midX, y: zoom.bounds.midY), to: nil).y
    }
}
