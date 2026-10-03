import BrumeCore
import Foundation
import GhosttyTerminal
import SwiftUI

// Un seul moteur pour tous les onglets, fenêtres et splits, comme Ghostty.
@MainActor private let sharedController: TerminalController = {
    let controller = TerminalController(
        terminalConfiguration: TerminalConfiguration {
            // Gérées par le patch zsh de Patches/ : le script du paquet les ignore.
            $0.withCustom("shell-integration-features", "ssh-env,ssh-terminfo")
            // L'app Ghostty double les deltas du trackpad avant le moteur, le paquet non :
            // sans ça, le défilement est deux fois plus lent que dans Ghostty.
            $0.withCustom("mouse-scroll-multiplier", "precision:2")
            // Repris de la config Ghostty de Jérémy. Shift+Entrée : saut de ligne dans Claude Code.
            $0.withCustom("keybind", "shift+enter=text:\\n")
            $0.withCustom("macos-option-as-alt", "left")
            // Option+flèche brut, sans le « mot précédent / suivant » de Ghostty.
            $0.withCustom("keybind", "alt+left=unbind")
            $0.withCustom("keybind", "alt+right=unbind")
        }
    )
    // Le moteur part en thème clair jusqu'à ce qu'une vue lui donne l'apparence : un nouveau
    // terminal aurait un fond clair, et sa barre de titre avec, le temps d'une image.
    let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    controller.setColorScheme(isDark ? .dark : .light)
    return controller
}()

/// Pour qu'un nouvel onglet ou une nouvelle fenêtre reprenne son zoom et son dossier.
@MainActor private weak var lastFocused: TerminalViewState?

enum FontSizeChange {
    case increase, decrease, reset
}

/// Les terminaux d'un onglet et leur découpage.
@MainActor @Observable
final class TerminalWorkspace: Identifiable {
    let id = UUID()
    private(set) var tree: SplitTree<UUID>
    private(set) var focusedID: UUID
    private(set) var states: [UUID: TerminalViewState] = [:]
    private(set) var searches: [UUID: TerminalSearch] = [:]
    @ObservationIgnored weak var window: NSWindow?
    /// Le dernier volet fermé : l'onglet part avec lui.
    @ObservationIgnored var onEmpty: () -> Void = {}
    @ObservationIgnored private var isVisible = true

    static var needsConfirmQuit: Bool {
        sharedController.needsConfirmQuit
    }

    init() {
        let id = UUID()
        tree = .pane(id)
        focusedID = id
        states[id] = makeState(id, inheriting: lastFocused, as: .window)
    }

    var focused: TerminalViewState {
        states[focusedID]!
    }

    var focusedSearch: TerminalSearch? {
        searches[focusedID]
    }

    var isSplit: Bool {
        tree.panes.count > 1
    }

    var hasRunningProcess: Bool {
        states.values.contains { $0.surface?.needsConfirmQuit == true }
    }

    /// Un onglet caché garde ses shells, mais ses terminaux arrêtent de dessiner.
    func setVisible(_ visible: Bool) {
        isVisible = visible
        for state in states.values {
            state.isSurfaceVisible = visible
        }
    }

    func split(_ axis: SplitAxis) {
        let id = UUID()
        states[id] = makeState(id, inheriting: focused, as: .split)
        tree = tree.splitting(focusedID, axis: axis, adding: id)
        focus(id)
    }

    func setRatio(_ ratio: CGFloat, at path: [Int]) {
        tree = tree.settingRatio(ratio, at: path)
    }

    func equalizeSplits() {
        tree = tree.equalized()
    }

    /// Cmd+0 ne remet que le terminal actif, comme Ghostty : ici, toute la fenêtre.
    func resetSizes() {
        for state in states.values {
            state.surface?.performBindingAction("reset_font_size")
        }
        equalizeSplits()
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
        lastFocused = states[id]
        states[id]?.requestFocus()
    }

    /// Un clic donne déjà le focus au terminal : on ne fait que suivre.
    func didFocus(_ id: UUID) {
        focusedID = id
        lastFocused = states[id]
    }

    /// Passe par le moteur, qui signale une commande en cours à `onClose`.
    func closeFocused() {
        focused.surface?.performBindingAction("close_surface")
    }

    func changeFontSize(_ change: FontSizeChange) {
        let action = switch change {
        case .increase: "increase_font_size:1"
        case .decrease: "decrease_font_size:1"
        case .reset: "reset_font_size"
        }
        focused.surface?.performBindingAction(action)
    }

    func toggleSearch() {
        if searches[focusedID] == nil {
            openSearch(in: focusedID, needle: "")
        } else {
            endSearch(in: focusedID)
        }
    }

    /// Le moteur répond par `start_search` avec la sélection : voir `makeState`.
    func searchSelection() {
        focused.surface?.performBindingAction("search_selection")
    }

    func endSearch(in id: UUID) {
        guard let search = searches.removeValue(forKey: id) else { return }
        search.end()
        focus(id)
    }

    private func openSearch(in id: UUID, needle: String) {
        guard let state = states[id] else { return }
        if let search = searches[id] {
            if !needle.isEmpty { search.needle = needle }
        } else {
            searches[id] = TerminalSearch(state: state, needle: needle)
        }
        searches[id]?.focusField()
    }

    private func close(_ id: UUID) {
        let order = tree.panes
        guard let index = order.firstIndex(of: id) else { return }
        guard let remaining = tree.removing(id) else { return onEmpty() }
        tree = remaining
        states[id] = nil
        searches[id] = nil
        if focusedID == id {
            focus(remaining.panes[max(index - 1, 0)])
        }
    }

    private func makeState(
        _ id: UUID,
        inheriting parent: TerminalViewState?,
        as context: TerminalSurfaceContext
    ) -> TerminalViewState {
        let state = TerminalViewState(controller: sharedController)
        state.isSurfaceVisible = isVisible
        // Comme Ghostty : un nouveau terminal part du zoom et du dossier de celui qui avait le focus.
        if let inherited = parent?.surface?.inheritedOptions(for: context) {
            if inherited.fontSize > 0 { state.configuration.fontSize = inherited.fontSize }
            state.configuration.workingDirectory = inherited.workingDirectory
        }
        // Cmd+W passe par le moteur, qui signale une commande en cours.
        state.onClose = { [weak self] processAlive in
            guard let self else { return }
            guard processAlive else { return close(id) }
            CloseConfirmation.terminal.ask(in: window) { [weak self] in self?.close(id) }
        }
        state.onStartSearch = { [weak self] in self?.openSearch(in: id, needle: $0) }
        state.onEndSearch = { [weak self] in self?.endSearch(in: id) }
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
