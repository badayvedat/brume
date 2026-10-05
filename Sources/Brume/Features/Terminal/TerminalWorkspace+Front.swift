import AppKit
import Combine

extension TerminalWorkspace {
    /// Seul SwiftUI ouvre une fenêtre : chaque fenêtre qui s'ouvre le pose ici pour le code AppKit.
    static var openNewWindow: (@MainActor () -> Void)?
    private static var waiting: [(TerminalWorkspace) -> Void] = []
    private static var sheetEnd: AnyCancellable?

    /// La fenêtre où poser une alerte de l'app : celle au premier plan, sinon la dernière ouverte,
    /// ramenée devant si Brume est masqué ou elle réduite dans le Dock. Jamais `keyWindow` tel
    /// quel : ce peut être le panneau d'un menu maison, qui emporterait la feuille en se fermant.
    static func front() -> TerminalWorkspace? {
        PopupMenu.close()
        let opened = all.compactMap { workspace in workspace.window.map { (workspace, $0) } }
        guard let last = opened.last else { return nil }
        // macOS peut refuser d'activer Brume (quitter depuis le Dock) : sans `WithoutActivation` ni
        // `Regardless`, la fenêtre resterait cachée et la question invisible.
        if NSApp.isHidden { NSApp.unhideWithoutActivation() }
        let (front, window) = NSApp.orderedWindows.lazy.compactMap { window in opened.first { $0.1 === window } }.first ?? last
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.orderFrontRegardless()
        window.makeKey()
        NSApp.activate()
        return front
    }

    /// `front()` sans feuille ouverte. Sinon `action` attend que la feuille se ferme, plutôt que la
    /// file d'AppKit qui partirait avec la fenêtre (dernier onglet fermé), ou qu'une fenêtre neuve
    /// s'ouvre s'il n'y en a plus.
    static func withFront(_ action: @escaping (TerminalWorkspace) -> Void) {
        guard let front = front(), let window = front.window else {
            whenOpened(action)
            openNewWindow?()
            return
        }
        guard window.attachedSheet != nil else { return action(front) }
        waiting.append(action)
        let center = NotificationCenter.default
        sheetEnd = center.publisher(for: NSWindow.didEndSheetNotification, object: window)
            .merge(with: center.publisher(for: NSWindow.willCloseNotification, object: window))
            .first()
            .sink { _ in serveWaitingActions() }
    }

    /// Pour la prochaine fenêtre qui s'ouvre, passée par `withFront`.
    static func whenOpened(_ action: @escaping (TerminalWorkspace) -> Void) {
        waiting.append(action)
    }

    /// Une fenêtre vient d'être rattachée, ou une feuille de se fermer : un tour plus tard, la
    /// fenêtre est à l'écran et la feuille partie.
    static func serveWaitingActions() {
        guard !waiting.isEmpty else { return }
        let actions = waiting
        waiting = []
        DispatchQueue.main.async { actions.forEach(withFront) }
    }
}
