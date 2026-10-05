import AppKit
import Combine

extension TerminalWorkspace {
    /// Seul SwiftUI ouvre une fenêtre : les commandes du menu (`TabCommands`) le posent ici pour le
    /// code AppKit.
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

    /// Le dossier où part le terminal de la prochaine fenêtre neuve, posé par `openTabs`.
    static var folderForNewWindow: String?

    /// Un onglet par dossier dans la fenêtre au premier plan. Sans fenêtre, dans la première qui
    /// s'ouvre : neuve, son terminal part du premier dossier plutôt que d'avoir un onglet vide à
    /// côté ; rouverte par la session au lancement, elle reçoit un onglet pour chacun.
    static func openTabs(in folders: [String]) {
        guard let first = folders.first else { return }
        let claimsNewWindow = all.isEmpty && folderForNewWindow == nil
        if claimsNewWindow { folderForNewWindow = first }
        let action = { (workspace: TerminalWorkspace) in
            let tookFirst = claimsNewWindow && folderForNewWindow == nil
            if claimsNewWindow { folderForNewWindow = nil }
            workspace.showingTerminals { workspace in
                for folder in tookFirst ? Array(folders.dropFirst()) : folders {
                    workspace.newTab(in: folder)
                }
            }
        }
        if all.contains(where: { $0.window != nil }) { return withFront(action) }
        whenOpened(action)
        // Sinon, une fenêtre s'ouvre déjà : celle du lancement, ou celle d'un dossier reçu juste avant.
        if claimsNewWindow { openNewWindow?() }
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
