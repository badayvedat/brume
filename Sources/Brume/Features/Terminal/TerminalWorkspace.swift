import BrumeCore
import Foundation
import GhosttyTerminal
import SwiftUI

// Un seul moteur pour tous les onglets, fenêtres et splits, comme Ghostty.
@MainActor private let sharedController = TerminalController(
    terminalConfiguration: TerminalConfiguration {
        // Gérées par le patch zsh de Patches/ : le script du paquet les ignore.
        $0.withCustom("shell-integration-features", "ssh-env,ssh-terminfo")
        // Le moteur avale ces raccourcis pour des actions que le paquet ne transmet pas :
        // on les rend au menu de l'app.
        for key in ["t", "n", "d", "shift+d", "[", "]", "alt+arrow_left", "alt+arrow_right", "alt+arrow_up", "alt+arrow_down"] {
            $0.withCustom("keybind", "super+\(key)=unbind")
        }
    }
)

/// Les terminaux d'une fenêtre (ou d'un onglet) et leur découpage.
@MainActor @Observable
final class TerminalWorkspace {
    private(set) var tree: SplitTree<UUID>
    private(set) var focusedID: UUID
    private(set) var states: [UUID: TerminalViewState] = [:]
    var onEmpty: () -> Void = {}

    init() {
        let id = UUID()
        tree = .pane(id)
        focusedID = id
        states[id] = makeState(id)
    }

    var focused: TerminalViewState {
        states[focusedID]!
    }

    var isSplit: Bool {
        tree.panes.count > 1
    }

    func split(_ axis: SplitAxis) {
        let id = UUID()
        states[id] = makeState(id)
        tree = tree.splitting(focusedID, axis: axis, adding: id)
        focus(id)
    }

    func setRatio(_ ratio: CGFloat, at path: [Int]) {
        tree = tree.settingRatio(ratio, at: path)
    }

    func focusNext() {
        tree.pane(after: focusedID).map(focus)
    }

    func focusPrevious() {
        tree.pane(before: focusedID).map(focus)
    }

    func focus(toward direction: SplitDirection) {
        tree.neighbor(of: focusedID, toward: direction).map(focus)
    }

    func focus(_ id: UUID) {
        focusedID = id
        states[id]?.requestFocus()
    }

    /// Un clic donne déjà le focus au terminal : on ne fait que suivre.
    func didFocus(_ id: UUID) {
        focusedID = id
    }

    private func close(_ id: UUID) {
        let order = tree.panes
        guard let index = order.firstIndex(of: id) else { return }
        guard let remaining = tree.removing(id) else {
            onEmpty()
            return
        }
        tree = remaining
        states[id] = nil
        if focusedID == id {
            focus(remaining.panes[max(index - 1, 0)])
        }
    }

    private func makeState(_ id: UUID) -> TerminalViewState {
        let state = TerminalViewState(controller: sharedController)
        state.onClose = { [weak self] _ in self?.close(id) }
        return state
    }
}

private struct TerminalWorkspaceKey: FocusedValueKey {
    typealias Value = TerminalWorkspace
}

extension FocusedValues {
    var terminalWorkspace: TerminalWorkspace? {
        get { self[TerminalWorkspaceKey.self] }
        set { self[TerminalWorkspaceKey.self] = newValue }
    }
}
