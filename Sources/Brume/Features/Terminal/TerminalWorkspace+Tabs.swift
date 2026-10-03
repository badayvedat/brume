import BrumeCore
import Foundation
import GhosttyTerminal

/// Ce qui porte un nom, une couleur et une icône : un onglet, ou un split d'un groupe.
enum TabItem: Hashable {
    case tab(UUID), pane(UUID)
}

extension TerminalWorkspace {
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

    private func close(_ tabs: [UUID]) {
        guard !tabs.isEmpty else { return }
        guard tabs.flatMap(layout.panes(of:)).contains(where: hasRunningCommand) else { return tabs.forEach(removeTab) }
        CloseConfirmation.tabs.ask(in: window) { [weak self] in tabs.forEach { self?.removeTab($0) } }
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
}
