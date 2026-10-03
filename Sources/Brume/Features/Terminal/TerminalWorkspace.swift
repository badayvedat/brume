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


/// Une fenêtre comme Muxy : des zones, chacune avec sa barre d'onglets, un terminal par onglet.
@MainActor @Observable
final class TerminalWorkspace {
    private(set) var layout: WindowLayout<UUID, UUID>
    private(set) var states: [UUID: TerminalViewState] = [:]
    private(set) var searches: [UUID: TerminalSearch] = [:]
    /// Le nom choisi d'un onglet ; sans, il affiche le titre de son terminal.
    private(set) var customTitles: [UUID: String] = [:]
    private(set) var colors: [UUID: TabColor] = [:]
    private(set) var renamingID: UUID?
    private(set) var drop: WindowLayout<UUID, UUID>.Drop?
    /// Toute la fenêtre et la hauteur d'une barre d'onglets, posées par `TerminalScreen`.
    @ObservationIgnored var bounds: CGRect = .zero
    @ObservationIgnored var barHeight: CGFloat = 32
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var closeGuard: WindowCloseGuard?
    /// La place de la fenêtre restaurée, posée quand elle s'ouvre.
    @ObservationIgnored private var savedFrame: CGRect?

    static var needsConfirmQuit: Bool {
        sharedController.needsConfirmQuit
    }

    /// Nil : une fenêtre neuve, un onglet dans le dossier du terminal actif.
    init(restoring saved: SavedWindow? = nil) {
        guard let saved, !saved.layout.tabs.isEmpty else {
            let id = UUID()
            layout = WindowLayout(area: UUID(), tab: id)
            states[id] = makeState(id, inheriting: lastFocused, as: .window)
            return
        }
        layout = saved.layout
        savedFrame = saved.frame
        for id in saved.layout.tabs {
            let tab = saved.tabs[id]
            let state = makeState(id, inheriting: nil, as: .window)
            state.configuration.workingDirectory = tab?.workingDirectory
            state.isSurfaceVisible = saved.layout.isShown(id)
            states[id] = state
            customTitles[id] = tab?.customTitle
            colors[id] = tab?.color
        }
    }

    /// Ce que la fenêtre retrouvera au prochain lancement.
    var snapshot: SavedWindow {
        let tabs = Dictionary(uniqueKeysWithValues: layout.tabs.map { id in
            (id, SavedTab(workingDirectory: states[id]?.workingDirectory, customTitle: customTitles[id], color: colors[id]))
        })
        return SavedWindow(layout: layout, tabs: tabs, frame: window?.frame)
    }

    var focusedID: UUID {
        layout.focusedTab
    }

    var focused: TerminalViewState {
        states[focusedID]!
    }

    var focusedSearch: TerminalSearch? {
        searches[focusedID]
    }

    var isSplit: Bool {
        layout.tree.panes.count > 1
    }

    func attach(to window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        window.tabbingMode = .disallowed
        if let savedFrame {
            window.setFrame(savedFrame, display: true)
            self.savedFrame = nil
        }
        closeGuard = WindowCloseGuard(on: window) { [weak self] window in
            guard let self, states.values.contains(where: Self.isRunning) else { return true }
            (states.count > 1 ? CloseConfirmation.window : .terminal).ask(in: window) { window.close() }
            return false
        }
    }

    /// Comme le bouton rouge : passe par la confirmation de `WindowCloseGuard`.
    func closeWindow() {
        window?.performClose(nil)
    }

    // MARK: Onglets

    func newTab(in area: UUID? = nil) {
        if let area { apply(layout.focusing(area)) }
        let id = UUID()
        states[id] = makeState(id, inheriting: focused, as: .window)
        apply(layout.addingTab(id))
    }

    func select(_ id: UUID) {
        apply(layout.selecting(id))
    }

    func select(number: Int) {
        apply(layout.selecting(number: number))
    }

    func selectNext() {
        apply(layout.selecting(offset: 1))
    }

    func selectPrevious() {
        apply(layout.selecting(offset: -1))
    }

    func move(_ id: UUID, to index: Int) {
        layout = layout.moving(id, to: index)
    }

    /// La croix d'un onglet : confirme si une commande y tourne.
    func close(_ id: UUID) {
        guard let state = states[id] else { return }
        guard Self.isRunning(state) else { return remove(id) }
        // Sa feuille parle de cet onglet : on l'affiche avant de demander.
        select(id)
        CloseConfirmation.tab.ask(in: window) { [weak self] in self?.remove(id) }
    }

    func closeOthers(of id: UUID) {
        close(layout.tabs(besides: id))
    }

    func closeRight(of id: UUID) {
        close(layout.tabs(rightOf: id))
    }

    func color(of id: UUID) -> TabColor? {
        colors[id]
    }

    func setColor(_ color: TabColor?, of id: UUID) {
        colors[id] = color
    }

    func title(of id: UUID) -> String? {
        customTitles[id]
    }

    func startRenaming(_ id: UUID? = nil) {
        let id = id ?? focusedID
        select(id)
        renamingID = id
    }

    /// Nil : renommage annulé. Le champ qui disparaît rappelle cette fonction en perdant le focus :
    /// seul le premier appel compte.
    func finishRenaming(_ id: UUID, input: String?, displayed: String) {
        guard renamingID == id else { return }
        renamingID = nil
        if let input {
            customTitles[id] = TabTitle.renamed(input: input, displayed: displayed, current: customTitles[id])
        }
        focus(focusedID)
    }

    func resetTitle(_ id: UUID) {
        customTitles[id] = nil
    }

    // MARK: Zones

    func split(_ axis: SplitAxis, from area: UUID? = nil) {
        if let area { apply(layout.focusing(area)) }
        let id = UUID()
        states[id] = makeState(id, inheriting: focused, as: .split)
        apply(layout.splitting(toward: axis == .horizontal ? .right : .down, area: UUID(), tab: id))
    }

    func setRatio(_ ratio: CGFloat, at path: [Int]) {
        layout = layout.settingRatio(ratio, at: path)
    }

    func equalizeSplits() {
        layout = layout.equalized()
    }

    /// Cmd+0 ne remet que le terminal actif, comme Ghostty : ici, toute la fenêtre.
    func resetSizes() {
        for state in states.values {
            state.surface?.performBindingAction("reset_font_size")
        }
        equalizeSplits()
    }

    func focusNext() {
        layout.tree.pane(after: layout.focusedArea).map(focusArea)
    }

    func focusPrevious() {
        layout.tree.pane(before: layout.focusedArea).map(focusArea)
    }

    func focus(toward direction: SplitDirection) {
        layout.tree.neighbor(of: layout.focusedArea, toward: direction).map(focusArea)
    }

    func moveFocusedTab(toward direction: SplitDirection) {
        let id = focusedID
        apply(layout.movingFocusedTab(toward: direction, newArea: UUID()))
        focus(id)
    }

    private func focusArea(_ area: UUID) {
        apply(layout.focusing(area))
        focus(focusedID)
    }

    // MARK: Terminal actif

    func focus(_ id: UUID) {
        apply(layout.selecting(id))
        lastFocused = states[id]
        states[id]?.requestFocus()
    }

    /// Un clic donne déjà le focus au terminal : on ne fait que suivre.
    func didFocus(_ id: UUID) {
        layout = layout.selecting(id)
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

    // MARK: Glisser un onglet

    /// Hors de sa barre. Nil : plus de glisser en cours, ou rien à proposer ici.
    func hoverDrop(dragging id: UUID, at point: CGPoint?) {
        let new = point.flatMap { layout.drop(of: id, at: $0, in: bounds, barHeight: barHeight) }
        if new != drop { drop = new }
    }

    func performDrop() {
        guard let drop else { return }
        self.drop = nil
        apply(layout.dropping(drop, newArea: UUID()))
        focus(drop.tab)
    }

    // MARK: Interne

    private func close(_ ids: [UUID]) {
        guard !ids.isEmpty else { return }
        guard ids.contains(where: { states[$0].map(Self.isRunning) ?? false }) else { return ids.forEach(remove) }
        CloseConfirmation.tabs.ask(in: window) { [weak self] in ids.forEach { self?.remove($0) } }
    }

    private static func isRunning(_ state: TerminalViewState) -> Bool {
        state.surface?.needsConfirmQuit == true
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

    private func remove(_ id: UUID) {
        // `close()` et pas `performClose` : la confirmation a déjà eu lieu.
        guard let remaining = layout.removing(id) else {
            window?.close()
            return
        }
        states[id] = nil
        searches[id] = nil
        customTitles[id] = nil
        colors[id] = nil
        apply(remaining)
    }

    /// Seuls les onglets affichés dessinent ; les autres gardent leur shell. Le focus suit l'onglet actif.
    private func apply(_ new: WindowLayout<UUID, UUID>) {
        let previous = layout.focusedTab
        layout = new
        for (id, state) in states {
            state.isSurfaceVisible = new.isShown(id)
        }
        if new.focusedTab != previous {
            lastFocused = states[new.focusedTab]
            states[new.focusedTab]?.requestFocus()
        }
    }

    private func makeState(
        _ id: UUID,
        inheriting parent: TerminalViewState?,
        as context: TerminalSurfaceContext
    ) -> TerminalViewState {
        let state = TerminalViewState(controller: sharedController)
        // Comme Ghostty : un nouveau terminal part du zoom et du dossier de celui qui avait le focus.
        if let inherited = parent?.surface?.inheritedOptions(for: context) {
            if inherited.fontSize > 0 { state.configuration.fontSize = inherited.fontSize }
            state.configuration.workingDirectory = inherited.workingDirectory
        }
        // Cmd+W passe par le moteur, qui signale une commande en cours.
        state.onClose = { [weak self] processAlive in
            guard let self else { return }
            guard processAlive else { return remove(id) }
            CloseConfirmation.terminal.ask(in: window) { [weak self] in self?.remove(id) }
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
