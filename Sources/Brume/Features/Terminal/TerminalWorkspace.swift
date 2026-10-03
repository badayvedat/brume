import BrumeCore
import Foundation
import GhosttyTerminal
import SwiftUI

// Un seul moteur pour tous les onglets, fenêtres et splits, comme Ghostty.
@MainActor private let sharedController: TerminalController = {
    let controller = TerminalController(terminalConfiguration: engineConfiguration(engineOptions))
    // Brume reste sombre : sans ça, le moteur part en clair le temps qu'une vue lui donne l'apparence.
    controller.setColorScheme(.dark)
    return controller
}()

/// Ce que les réglages changent dans la config du moteur, commune à toutes les fenêtres.
private struct EngineOptions {
    var isTranslucent = false
    var font = TerminalFont.standard
}

@MainActor private var engineOptions = EngineOptions() {
    didSet { sharedController.setTerminalConfiguration(engineConfiguration(engineOptions)) }
}

private func engineConfiguration(_ options: EngineOptions) -> TerminalConfiguration {
    TerminalConfiguration {
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
        // En verre, le voile vient du fond de la fenêtre, d'un seul tenant sous les onglets et
        // les terminaux : le moteur ne peint plus son fond par-dessus.
        $0.withBackgroundOpacity(options.isTranslucent ? 0 : 1)
        if let family = options.font.family {
            $0.withFontFamily(family)
        }
        $0.withFontSize(Float(options.font.size))
    }
}

/// Les fenêtres ouvertes, dans l'ordre où elles se sont ouvertes : la session les rouvrira
/// dans le même ordre, et un changement de couleurs passe par tous leurs terminaux.
@MainActor private var openWorkspaces: [WeakWorkspace] = []

private struct WeakWorkspace {
    weak var value: TerminalWorkspace?
}

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
    /// La page de réglages affichée à la place des terminaux, qui restent ouverts dessous.
    private(set) var settingsSection: SettingsSection?
    /// Toute la fenêtre et la hauteur d'une barre d'onglets, posées par `TerminalSplitView` pour
    /// calculer les dépôts : les vues prennent la hauteur du `WindowTitlebar`, observé, pas celle-ci.
    @ObservationIgnored var bounds: CGRect = .zero
    @ObservationIgnored var barHeight: CGFloat = 32
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var closeGuard: WindowCloseGuard?
    /// La place de la fenêtre restaurée, posée quand elle s'ouvre.
    @ObservationIgnored private var savedFrame: CGRect?

    static var needsConfirmQuit: Bool {
        sharedController.needsConfirmQuit
    }

    /// Avant le premier terminal : il s'ouvre déjà avec le thème et la police choisis.
    static func prepareEngine(_ settings: AppSettings) {
        engineOptions.font = settings.font
        ThemeFade.start(with: TerminalThemes.colors(for: settings.appearance))
    }

    /// Le moteur est commun à toutes les fenêtres : sans changement, l'appel ne fait rien.
    static func setTranslucent(_ isTranslucent: Bool) {
        engineOptions.isTranslucent = isTranslucent
    }

    static func setFont(_ font: TerminalFont) {
        engineOptions.font = font
    }

    /// Par les terminaux et pas le moteur seul : chacun doit reprendre la couleur de fond du thème.
    static func applyEngineTheme(_ theme: TerminalTheme) {
        sharedController.setTheme(theme)
        for workspace in all {
            for state in workspace.states.values {
                state.setTheme(theme)
            }
        }
    }

    static var all: [TerminalWorkspace] {
        openWorkspaces.removeAll { $0.value == nil }
        return openWorkspaces.compactMap(\.value)
    }

    /// Nil : une fenêtre neuve, un onglet dans le dossier du terminal actif.
    init(restoring saved: SavedWindow? = nil) {
        guard let saved, saved.layout.isConsistent else {
            let id = UUID()
            layout = WindowLayout(area: UUID(), tab: id)
            states[id] = makeState(id, inheriting: lastFocused, as: .window)
            openWorkspaces.append(WeakWorkspace(value: self))
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
        openWorkspaces.append(WeakWorkspace(value: self))
    }

    /// Ce que la fenêtre retrouvera au prochain lancement.
    var snapshot: SavedWindow {
        let tabs = Dictionary(uniqueKeysWithValues: layout.tabs.map { id -> (UUID, SavedTab) in
            // Le dossier de départ tant que le shell n'a pas encore annoncé le sien.
            let folder = states[id].flatMap { $0.workingDirectory ?? $0.configuration.workingDirectory }
            return (id, SavedTab(workingDirectory: folder, customTitle: customTitles[id], color: colors[id]))
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
        // Pas sur un écran débranché depuis : la fenêtre rouvrirait invisible.
        if let savedFrame, let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(savedFrame) }) {
            window.setFrame(window.constrainFrameRect(savedFrame, to: screen), display: true)
        }
        savedFrame = nil
        closeGuard = WindowCloseGuard(on: window) { [weak self] window in
            guard let self, states.values.contains(where: Self.isRunning) else { return true }
            (states.count > 1 ? CloseConfirmation.window : .terminal).ask(in: window) { window.close() }
            return false
        }
    }

    /// Les raccourcis agissent encore sur les terminaux cachés dessous, mais aucun ne reprend le
    /// clavier avant le retour : la frappe irait dans un terminal qu'on ne voit pas.
    func showSettings(_ section: SettingsSection? = nil) {
        settingsSection = section ?? settingsSection ?? .appearance
        window?.makeFirstResponder(nil)
        updateSurfaces()
    }

    func closeSettings() {
        settingsSection = nil
        updateSurfaces()
        focus(focusedID)
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

    /// Retour à un seul onglet : le terminal actif reste, avec son shell ; les autres onglets et
    /// zones se ferment, couleurs, noms et taille du texte reviennent à la normale.
    func reset() {
        let kept = focusedID
        let others = layout.tabs.filter { $0 != kept }
        let reset = { [weak self] in
            guard let self else { return }
            for id in others {
                states[id] = nil
                searches[id] = nil
            }
            customTitles = [:]
            colors = [:]
            apply(WindowLayout(area: layout.focusedArea, tab: kept))
            states[kept]?.surface?.performBindingAction("reset_font_size")
            focus(kept)
        }
        guard others.contains(where: { states[$0].map(Self.isRunning) ?? false }) else { return reset() }
        CloseConfirmation.tabs.ask(in: window, then: reset)
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
        guard settingsSection == nil else { return }
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
        if settingsSection == nil { states[id]?.requestFocus() }
    }

    /// Un clic donne déjà le focus au terminal : on ne fait que suivre.
    func didFocus(_ id: UUID) {
        layout = layout.selecting(id)
        lastFocused = states[id]
    }

    /// Passe par le moteur, qui signale une commande en cours à `onClose`.
    /// Sur la page de réglages, Cmd+W la referme plutôt que le terminal caché dessous.
    func closeFocused() {
        guard settingsSection == nil else { return closeSettings() }
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
        guard settingsSection == nil else { return }
        if searches[focusedID] == nil {
            openSearch(in: focusedID, needle: "")
        } else {
            endSearch(in: focusedID)
        }
    }

    /// Le moteur répond par `start_search` avec la sélection : voir `makeState`.
    func searchSelection() {
        guard settingsSection == nil else { return }
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
        updateSurfaces()
        if new.focusedTab != previous {
            lastFocused = states[new.focusedTab]
            if settingsSection == nil { states[new.focusedTab]?.requestFocus() }
        }
    }

    /// Seuls les terminaux affichés se dessinent : ni les onglets cachés, ni rien sous les réglages.
    private func updateSurfaces() {
        let shown = settingsSection == nil ? Set(layout.areas.values.map(\.selected)) : []
        for (id, state) in states {
            state.isSurfaceVisible = shown.contains(id)
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
