import AppKit
import BrumeCore
import SwiftUI

/// Les onglets d'une fenêtre. Gérés ici plutôt qu'en onglets natifs : une seule liste,
/// que la barre du haut affiche et que la vue agents listera.
@MainActor @Observable
final class TerminalTabs {
    private var list: TabList<UUID>
    private var workspaces: [UUID: TerminalWorkspace] = [:]
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var closeGuard: WindowCloseGuard?

    init() {
        let first = TerminalWorkspace()
        list = TabList(first.id)
        adopt(first)
    }

    var tabs: [TerminalWorkspace] {
        list.tabs.compactMap { workspaces[$0] }
    }

    var selected: TerminalWorkspace {
        workspaces[list.selected]!
    }

    func attach(to window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        window.tabbingMode = .disallowed
        for workspace in workspaces.values {
            workspace.window = window
        }
        closeGuard = WindowCloseGuard(on: window) { [weak self] window in
            guard let self, workspaces.values.contains(where: \.hasRunningProcess) else { return true }
            (list.tabs.count > 1 ? CloseConfirmation.window : .terminal).ask(in: window) { window.close() }
            return false
        }
    }

    func newTab() {
        let workspace = TerminalWorkspace()
        adopt(workspace)
        show(list.inserting(workspace.id))
    }

    func select(_ id: UUID) {
        show(list.selecting(id))
    }

    func select(number: Int) {
        show(list.selecting(number: number))
    }

    func selectNext() {
        show(list.selecting(offset: 1))
    }

    func selectPrevious() {
        show(list.selecting(offset: -1))
    }

    /// La croix d'un onglet : confirme si une commande y tourne.
    func close(_ id: UUID) {
        guard let workspace = workspaces[id] else { return }
        guard workspace.hasRunningProcess else { return remove(id) }
        // Sa feuille parle de cet onglet : on l'affiche avant de demander.
        select(id)
        CloseConfirmation.tab.ask(in: window) { [weak self] in self?.remove(id) }
    }

    /// Comme le bouton rouge : passe par la confirmation de `WindowCloseGuard`.
    func closeWindow() {
        window?.performClose(nil)
    }

    private func adopt(_ workspace: TerminalWorkspace) {
        let id = workspace.id
        workspace.window = window
        workspace.onEmpty = { [weak self] in self?.remove(id) }
        workspaces[id] = workspace
    }

    private func remove(_ id: UUID) {
        // `close()` et pas `performClose` : la confirmation a déjà eu lieu.
        guard let remaining = list.removing(id) else {
            window?.close()
            return
        }
        workspaces[id] = nil
        show(remaining)
    }

    private func show(_ new: TabList<UUID>) {
        let changed = new.selected != list.selected
        list = new
        for (id, workspace) in workspaces {
            workspace.setVisible(id == new.selected)
        }
        if changed {
            selected.focus(selected.focusedID)
        }
    }
}

private struct TerminalTabsKey: FocusedValueKey {
    typealias Value = TerminalTabs
}

extension FocusedValues {
    var terminalTabs: TerminalTabs? {
        get { self[TerminalTabsKey.self] }
        set { self[TerminalTabsKey.self] = newValue }
    }
}
