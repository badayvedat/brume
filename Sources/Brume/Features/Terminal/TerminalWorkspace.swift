import BrumeCore
import Combine
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

/// Ce qui porte un nom, une couleur et une icône : un onglet, ou un split d'un groupe.
enum TabItem: Hashable {
    case tab(UUID), pane(UUID)
}

/// Une fenêtre comme Ghostty : des onglets, chacun divisé en splits, un terminal par split.
@MainActor @Observable
final class TerminalWorkspace {
    private(set) var layout: WindowLayout<UUID, UUID> {
        // Un autre split prend le clavier, ou l'onglet change : fin de l'agrandissement.
        didSet {
            if let zoomedPane, layout.focusedPane != zoomedPane || !isSplit { self.zoomedPane = nil }
        }
    }
    /// Les terminaux, par split.
    private(set) var states: [UUID: TerminalViewState] = [:]
    private(set) var searches: [UUID: TerminalSearch] = [:]
    /// Le titre et la progression que chaque terminal annonce, relevés ici : un onglet ou un
    /// groupe qui les affiche se met à jour sans observer chacun de ses terminaux.
    private(set) var terminalTitles: [UUID: String] = [:]
    private(set) var paneProgress: [UUID: TerminalProgress] = [:]
    /// Les noms, couleurs et icônes choisis, des onglets et des splits d'un groupe.
    private(set) var labels = WindowLabels<UUID, UUID>()
    /// Les onglets divisés repliés dans la barre latérale.
    private(set) var collapsed: Set<UUID> = []
    private(set) var renaming: TabItem?
    /// Les splits cachés où une commande ou une progression a fini, où ça a sonné ou notifié
    /// (Claude Code qui attend une réponse) depuis qu'on les a quittés.
    private(set) var activity: Set<UUID> = []
    /// Le split agrandi à tout l'onglet le temps de lire, comme `toggle_split_zoom` de Ghostty.
    private(set) var zoomedPane: UUID?
    private(set) var drop: WindowLayout<UUID, UUID>.Drop?
    /// La page de réglages affichée à la place des terminaux, qui restent ouverts dessous.
    private(set) var settingsSection: SettingsSection?
    /// La place des splits, posée par `TerminalSplitView` pour calculer les dépôts.
    @ObservationIgnored var bounds: CGRect = .zero
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var closeGuard: WindowCloseGuard?
    @ObservationIgnored private var watchers: [UUID: [AnyCancellable]] = [:]
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
            let pane = UUID()
            layout = WindowLayout(tab: UUID(), pane: pane)
            states[pane] = makeState(pane, inheriting: lastFocused, as: .window)
            openWorkspaces.append(WeakWorkspace(value: self))
            return
        }
        layout = saved.layout
        savedFrame = saved.frame
        let shown = Set(saved.layout.panes(of: saved.layout.selectedTab))
        for pane in saved.layout.panes {
            let state = makeState(pane, inheriting: nil, as: .window)
            state.configuration.workingDirectory = saved.panes[pane]?.workingDirectory
            state.isSurfaceVisible = shown.contains(pane)
            states[pane] = state
        }
        for tab in saved.layout.tabs {
            guard let info = saved.tabs[tab] else { continue }
            if !info.label.isEmpty { labels.tabs[tab] = info.label }
            labels.groupNumbers[tab] = info.groupNumber
            if info.isCollapsed { collapsed.insert(tab) }
        }
        for (pane, info) in saved.panes {
            labels.panes[pane] = info.label
        }
        // Une session sans numéros de groupe les reçoit ici.
        labels = labels.reconciled(from: layout, to: layout)
        openWorkspaces.append(WeakWorkspace(value: self))
    }

    /// Ce que la fenêtre retrouvera au prochain lancement.
    var snapshot: SavedWindow {
        let tabs = Dictionary(uniqueKeysWithValues: layout.tabs.map { tab in
            (tab, SavedTab(label: labels.tabs[tab], isCollapsed: collapsed.contains(tab), groupNumber: labels.groupNumbers[tab]))
        })
        let panes = Dictionary(uniqueKeysWithValues: layout.panes.map { pane in
            // Le dossier de départ tant que le shell n'a pas encore annoncé le sien.
            (pane, SavedPane(
                workingDirectory: states[pane].flatMap { $0.workingDirectory ?? $0.configuration.workingDirectory },
                label: labels.panes[pane]
            ))
        })
        return SavedWindow(layout: layout, tabs: tabs, panes: panes, frame: window?.frame)
    }

    /// Le split qui a le clavier, dans l'onglet affiché.
    var focusedID: UUID {
        layout.focusedPane
    }

    var focused: TerminalViewState {
        states[focusedID]!
    }

    var focusedSearch: TerminalSearch? {
        searches[focusedID]
    }

    /// L'onglet affiché est divisé.
    var isSplit: Bool {
        layout.isSplit(layout.selectedTab)
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
    /// clavier avant le retour : la frappe irait dans un terminal qu'on ne voit pas. Le focus va au
    /// contenu SwiftUI, pas à la fenêtre : Tab mène alors au premier champ des réglages.
    func showSettings(_ section: SettingsSection? = nil) {
        settingsSection = section ?? settingsSection ?? .appearance
        window?.makeFirstResponder(window?.contentView)
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

    /// ⌘T l'ouvre après l'onglet actif, comme Ghostty ; les boutons +, en bout de liste où ils sont.
    func newTab(atEnd: Bool = false) {
        let pane = UUID()
        states[pane] = makeState(pane, inheriting: focused, as: .window)
        apply(atEnd ? layout.appendingTab(UUID(), pane: pane) : layout.addingTab(UUID(), pane: pane))
    }

    func select(_ tab: UUID) {
        apply(layout.selecting(tab))
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

    func move(_ tab: UUID, to index: Int) {
        layout = layout.moving(tab, to: index)
    }

    func moveSelectedTab(by offset: Int) {
        layout = layout.moving(layout.selectedTab, by: offset)
    }

    /// La croix d'un onglet : confirme si une commande tourne dans un de ses splits.
    func close(_ tab: UUID) {
        guard layout.panes(of: tab).contains(where: hasRunningCommand) else { return removeTab(tab) }
        // Sa feuille parle de cet onglet : on l'affiche avant de demander.
        select(tab)
        CloseConfirmation.tab.ask(in: window) { [weak self] in self?.removeTab(tab) }
    }

    func closeSelectedTab() {
        close(layout.selectedTab)
    }

    func closeOthers(of tab: UUID) {
        close(layout.tabs(besides: tab))
    }

    func closeAfter(_ tab: UUID) {
        close(layout.tabs(after: tab))
    }

    /// Retour à un seul onglet : le terminal actif reste, avec son shell ; les autres onglets et
    /// splits se ferment, couleurs, icônes, noms et taille du texte reviennent à la normale.
    func reset() {
        let kept = focusedID
        let others = layout.panes.filter { $0 != kept }
        let reset = { [weak self] in
            guard let self else { return }
            others.forEach(forget)
            labels = WindowLabels()
            collapsed = []
            apply(WindowLayout(tab: layout.selectedTab, pane: kept))
            states[kept]?.surface?.performBindingAction("reset_font_size")
            focus(kept)
        }
        guard others.contains(where: hasRunningCommand) else { return reset() }
        CloseConfirmation.tabs.ask(in: window, then: reset)
    }

    func label(of item: TabItem) -> TabLabel? {
        switch item {
        case let .tab(tab): labels.tabs[tab]
        case let .pane(pane): labels.panes[pane]
        }
    }

    func setColor(_ color: TabColor?, of item: TabItem) {
        updateLabel(of: item) { $0.color = color }
    }

    /// Sans icône choisie, celle du terminal.
    func icon(of item: TabItem) -> TabIcon {
        label(of: item)?.icon ?? .terminal
    }

    func setIcon(_ icon: TabIcon, of item: TabItem) {
        updateLabel(of: item) { $0.icon = icon == .terminal ? nil : icon }
    }

    /// Celle choisie, sinon un split pour un groupe : on le reconnaît en haut comme sur le côté.
    func symbol(of tab: UUID) -> String {
        labels.tabs[tab]?.icon?.symbol ?? (layout.isSplit(tab) ? "square.split.2x1" : TabIcon.terminal.symbol)
    }

    /// Le nom choisi, sinon celui qu'annonce le terminal : la commande en cours, ou le dernier
    /// dossier de son chemin, entier dans l'en-tête. Un groupe sans nom choisi s'appelle « Groupe 1 »,
    /// « Groupe 2 »…
    func displayedTitle(of item: TabItem) -> String {
        if let title = label(of: item)?.title { return title }
        switch item {
        case let .tab(tab):
            let panes = layout.panes(of: tab)
            guard panes.count == 1 else { return "\(L10n.text(.group)) \(labels.groupNumbers[tab] ?? 1)" }
            return terminalTitle(panes[0])
        case let .pane(pane):
            return terminalTitle(pane)
        }
    }

    /// Celle d'un de ses splits : l'onglet travaille tant que l'un d'eux travaille.
    func progress(of tab: UUID) -> TerminalProgress? {
        layout.panes(of: tab).lazy.compactMap { self.paneProgress[$0] }.first
    }

    func hasActivity(_ tab: UUID) -> Bool {
        layout.panes(of: tab).contains(where: activity.contains)
    }

    /// Nil : l'onglet affiché.
    func startRenaming(_ item: TabItem? = nil) {
        guard settingsSection == nil else { return }
        let item = item ?? .tab(layout.selectedTab)
        switch item {
        case let .tab(tab): select(tab)
        case let .pane(pane): focus(pane)
        }
        renaming = item
    }

    /// Nil : renommage annulé. Le champ qui disparaît rappelle cette fonction en perdant le focus :
    /// seul le premier appel compte.
    func finishRenaming(_ item: TabItem, input: String?, displayed: String) {
        guard renaming == item else { return }
        renaming = nil
        if let input {
            updateLabel(of: item) { $0.title = TabTitle.renamed(input: input, displayed: displayed, current: $0.title) }
        }
        focus(focusedID)
    }

    func resetTitle(_ item: TabItem) {
        updateLabel(of: item) { $0.title = nil }
    }

    func toggleCollapsed(_ tab: UUID) {
        collapsed.formSymmetricDifference([tab])
    }

    /// Chaque split de l'onglet part dans son propre onglet ; le clavier reste où il était.
    func separate(_ tab: UUID) {
        let pane = layout.splits[tab]?.focused
        apply(layout.separating(tab, into: layout.panes(of: tab).dropFirst().map { _ in UUID() }))
        if let pane { focus(pane) }
    }

    func detach(_ pane: UUID) {
        apply(layout.detaching(pane, into: UUID()))
        focus(pane)
    }

    // MARK: Splits

    /// Nil : le split actif. Le groupe se déplie : le nouveau split s'y voit.
    func split(_ axis: SplitAxis, from origin: UUID? = nil) {
        if let origin { focus(origin) }
        let pane = UUID()
        states[pane] = makeState(pane, inheriting: focused, as: .split)
        collapsed.remove(layout.selectedTab)
        apply(layout.splitting(toward: axis == .horizontal ? .right : .down, pane: pane))
    }

    func setRatio(_ ratio: CGFloat, at path: [Int]) {
        layout = layout.settingRatio(ratio, at: path)
    }

    /// Nil : le terminal actif.
    func toggleZoom(_ pane: UUID? = nil) {
        if let pane { focus(pane) }
        zoomedPane = zoomedPane == nil && isSplit ? focusedID : nil
        updateSurfaces()
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
        apply(layout.focusingPane(offset: 1))
    }

    func focusPrevious() {
        apply(layout.focusingPane(offset: -1))
    }

    func focus(toward direction: SplitDirection) {
        apply(layout.focusingPane(toward: direction))
    }

    /// Deux splits d'un groupe échangent leur place, glissés l'un sur l'autre dans la barre latérale.
    func swap(_ a: UUID, _ b: UUID) {
        layout = layout.swapping(a, b)
    }

    /// La croix d'un split dans la barre latérale : confirme si une commande y tourne.
    func closePane(_ pane: UUID) {
        guard states[pane] != nil else { return }
        guard hasRunningCommand(pane) else { return remove(pane) }
        focus(pane)
        CloseConfirmation.terminal.ask(in: window) { [weak self] in self?.remove(pane) }
    }

    // MARK: Terminal actif

    func focus(_ pane: UUID) {
        apply(layout.focusing(pane))
        lastFocused = states[pane]
        if settingsSection == nil { states[pane]?.requestFocus() }
    }

    /// Un clic donne déjà le focus au terminal : on ne fait que suivre.
    func didFocus(_ pane: UUID) {
        layout = layout.focusing(pane)
        lastFocused = states[pane]
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

    func endSearch(in pane: UUID) {
        guard let search = searches.removeValue(forKey: pane) else { return }
        search.end()
        focus(pane)
    }

    // MARK: Glisser un onglet

    /// Sur les terminaux. Nil : plus de glisser en cours, ou rien à proposer ici.
    func hoverDrop(dragging: WindowLayout<UUID, UUID>.Dragged, at point: CGPoint?) {
        if point != nil { unzoom() }
        let new = point.flatMap { layout.drop(of: dragging, at: $0, in: bounds) }
        if new != drop { drop = new }
    }

    /// Lâché sur les splits de l'onglet affiché, il les rejoint, avec son nom.
    func performDrop() {
        guard let drop else { return }
        self.drop = nil
        apply(layout.dropping(drop))
        focus(layout.focusedPane)
    }

    // MARK: Interne

    private func close(_ tabs: [UUID]) {
        guard !tabs.isEmpty else { return }
        guard tabs.flatMap(layout.panes(of:)).contains(where: hasRunningCommand) else { return tabs.forEach(removeTab) }
        CloseConfirmation.tabs.ask(in: window) { [weak self] in tabs.forEach { self?.removeTab($0) } }
    }

    private func hasRunningCommand(_ pane: UUID) -> Bool {
        states[pane].map(Self.isRunning) ?? false
    }

    private static func isRunning(_ state: TerminalViewState) -> Bool {
        state.surface?.needsConfirmQuit == true
    }

    private func openSearch(in pane: UUID, needle: String) {
        guard let state = states[pane] else { return }
        if let search = searches[pane] {
            if !needle.isEmpty { search.needle = needle }
        } else {
            searches[pane] = TerminalSearch(state: state, needle: needle)
        }
        searches[pane]?.focusField()
    }

    /// `close()` et pas `performClose` : la confirmation a déjà eu lieu.
    private func remove(_ pane: UUID) {
        guard let remaining = layout.removing(pane) else {
            window?.close()
            return
        }
        forget(pane)
        apply(remaining)
    }

    private func removeTab(_ tab: UUID) {
        let panes = layout.panes(of: tab)
        guard let remaining = layout.removingTab(tab) else {
            window?.close()
            return
        }
        panes.forEach(forget)
        apply(remaining)
    }

    private func forget(_ pane: UUID) {
        states[pane] = nil
        searches[pane] = nil
        watchers[pane] = nil
        terminalTitles[pane] = nil
        paneProgress[pane] = nil
        activity.remove(pane)
    }

    private func terminalTitle(_ pane: UUID) -> String {
        let title = terminalTitles[pane] ?? ""
        return title.isEmpty ? L10n.text(.terminal) : TabTitle.short(title)
    }

    private func updateLabel(of item: TabItem, _ change: (inout TabLabel) -> Void) {
        var label = label(of: item) ?? TabLabel()
        change(&label)
        let value = label.isEmpty ? nil : label
        switch item {
        case let .tab(tab): labels.tabs[tab] = value
        case let .pane(pane): labels.panes[pane] = value
        }
    }

    /// Seul l'onglet affiché dessine ; les autres gardent leurs shells. Le focus suit le split actif.
    private func apply(_ new: WindowLayout<UUID, UUID>) {
        let previous = layout.focusedPane
        let reconciled = labels.reconciled(from: layout, to: new)
        if reconciled != labels { labels = reconciled }
        // Un onglet redevenu seul oublie qu'il était replié : divisé à nouveau, il s'ouvre.
        let groups = Set(new.tabs.filter(new.isSplit))
        if !collapsed.isSubset(of: groups) { collapsed.formIntersection(groups) }
        layout = new
        updateSurfaces()
        if new.focusedPane != previous {
            lastFocused = states[new.focusedPane]
            if settingsSection == nil { states[new.focusedPane]?.requestFocus() }
        }
    }

    /// Les splits de l'onglet affiché, ou seulement celui agrandi.
    private var shownPanes: Set<UUID> {
        if let zoomedPane { return [zoomedPane] }
        return Set(layout.panes(of: layout.selectedTab))
    }

    /// Seuls les terminaux affichés se dessinent : ni les autres onglets, ni rien sous les réglages.
    private func updateSurfaces() {
        let shown = shownPanes
        if !activity.isDisjoint(with: shown) { activity.subtract(shown) }
        let drawn = settingsSection == nil ? shown : []
        for (pane, state) in states {
            state.isSurfaceVisible = drawn.contains(pane)
        }
    }

    private func unzoom() {
        guard zoomedPane != nil else { return }
        zoomedPane = nil
        updateSurfaces()
    }

    private func noteActivity(in pane: UUID) {
        guard !shownPanes.contains(pane) else { return }
        activity.insert(pane)
    }

    private func makeState(
        _ pane: UUID,
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
            guard processAlive else { return remove(pane) }
            CloseConfirmation.terminal.ask(in: window) { [weak self] in self?.remove(pane) }
        }
        watchers[pane] = [
            state.$title.removeDuplicates().sink { [weak self] in self?.terminalTitles[pane] = $0 },
            state.$progress.removeDuplicates().sink { [weak self] in self?.paneProgress[pane] = $0 },
            Publishers.Merge4(
                state.$lastCommandExitCode.dropFirst().map { _ in },
                state.$bellCount.dropFirst().map { _ in },
                state.$lastDesktopNotificationAt.dropFirst().map { _ in },
                // Une progression qui s'arrête : Claude Code a fini son tour.
                state.$progress.map { $0 != nil }.removeDuplicates().dropFirst().filter { !$0 }.map { _ in }
            )
            .sink { [weak self] in self?.noteActivity(in: pane) },
        ]
        state.makePlatformView = { [weak self] in
            let view = BrumeTerminalView(frame: .zero)
            view.onContextMenu = { [weak self] in
                guard let self else { return }
                TerminalContextMenu.show(for: pane, in: self)
            }
            return view
        }
        state.onStartSearch = { [weak self] in self?.openSearch(in: pane, needle: $0) }
        state.onEndSearch = { [weak self] in self?.endSearch(in: pane) }
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
