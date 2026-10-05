import AppKit
import BrumeCore
import UserNotifications

/// Ce qui prévient hors de la barre d'onglets : la pastille de l'icône du Dock et, Brume en
/// arrière-plan, une notification de macOS par terminal, qui remplace la précédente.
extension TerminalWorkspace {
    /// Les terminaux qui ont une notification dans le centre de notifications.
    private static var notified: Set<UUID> = []

    /// Le nombre de terminaux, toutes fenêtres, qui ont une activité non vue.
    static func updateDockBadge(isOn: Bool) {
        let count = isOn ? all.reduce(0) { $0 + $1.paneActivity.count } : 0
        let label = count > 0 ? "\(count)" : nil
        if NSApp.dockTile.badgeLabel != label { NSApp.dockTile.badgeLabel = label }
    }

    func updateDockBadge() {
        Self.updateDockBadge(isOn: settings?.showsDockBadge ?? true)
    }

    /// Au premier plan, la pastille de l'onglet suffit.
    func notify(_ event: TerminalEvent, in pane: UUID) {
        guard !NSApp.isActive, settings?.sendsNotifications == true, let notice = TerminalNotice(event),
              let tab = layout.tab(of: pane) else { return }
        let content = UNMutableNotificationContent()
        content.title = displayedTitle(of: layout.isSplit(tab) ? .pane(pane) : .tab(tab))
        content.subtitle = notice.subtitle
        content.body = notice.body
        content.sound = .default
        let request = UNNotificationRequest(identifier: pane.uuidString, content: content, trigger: nil)
        Self.notified.insert(pane)
        Task {
            let center = UNUserNotificationCenter.current()
            // Demandée au premier besoin, une seule fois : refusée, rien ne s'affiche, sans message.
            // `.badge` aussi : macOS règle la pastille du Dock avec les notifications de l'app.
            guard (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true, !NSApp.isActive else { return }
            try? await center.add(request)
        }
    }

    static func withdrawNotifications(of panes: some Sequence<UUID>) {
        let seen = notified.intersection(panes)
        guard !seen.isEmpty else { return }
        notified.subtract(seen)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: seen.map(\.uuidString))
    }

    static func withdrawAllNotifications() {
        notified = []
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    /// Le clic sur une notification : sa fenêtre devant, sur l'onglet et le terminal.
    static func reveal(_ pane: UUID) {
        guard let workspace = all.first(where: { $0.states[pane] != nil }), let window = workspace.window else { return }
        PopupMenu.close()
        bringToFront(window)
        workspace.showingTerminals { $0.focus(pane) }
    }

    /// De retour dans Brume : ce qui est à l'écran dans chaque fenêtre est vu.
    static func didBecomeActive() {
        for workspace in all {
            workspace.markSeen(workspace.shownPanes)
        }
    }
}
