import BrumeCore
import SwiftUI

/// La place d'un onglet dans ce qu'on voit : l'onglet affiché est plein ; un groupe déplié qui
/// l'est n'est qu'à mi-teinte, son split actif portant le plein.
enum TabHighlight {
    case none, half, full
}

extension View {
    /// Ce qu'un onglet ou un split d'un groupe font pareil : fond teinté, cadre du renommage,
    /// clic, double-clic, clic droit, survol et accessibilité.
    func tabBehavior(
        _ item: TabItem, in workspace: TerminalWorkspace, highlight: TabHighlight, isHovered: Binding<Bool>, isDragging: Bool, isVertical: Bool
    ) -> some View {
        modifier(TabBehavior(item: item, workspace: workspace, highlight: highlight, isHovered: isHovered, isDragging: isDragging, isVertical: isVertical))
    }

    /// Sur le titre seul : la croix, à côté, a la sienne. Le titre entier, que l'onglet peut couper,
    /// et l'état de la pastille, que la croix remplace au survol.
    func tabTooltip(_ item: TabItem, in workspace: TerminalWorkspace, isDragging: Bool) -> some View {
        contentShape(.rect)
            .tooltip(
                workspace.displayedTitle(of: item),
                detail: workspace.statusText(of: item),
                isEnabled: !isDragging && workspace.renaming != item
            )
    }
}

extension TerminalWorkspace {
    /// Ce que dit la pastille d'un onglet, d'un groupe ou d'un terminal d'un groupe.
    func statusText(of item: TabItem) -> String? {
        switch item {
        case let .tab(tab): TabStatus.text(progress: progress(of: tab), hasActivity: hasActivity(tab))
        case let .pane(pane): TabStatus.text(progress: paneProgress[pane], hasActivity: activity.contains(pane))
        }
    }
}

private struct TabBehavior: ViewModifier {
    let item: TabItem
    let workspace: TerminalWorkspace
    let highlight: TabHighlight
    @Binding var isHovered: Bool
    let isDragging: Bool
    let isVertical: Bool

    @Environment(\.accent) private var accent

    func body(content: Content) -> some View {
        content
            .background(hoverFill, in: .rect(cornerRadius: 6))
            // Le surlignage suit l'animation de la liste : une animation propre à la rangée
            // prendrait le pas sur son glissement, et l'onglet voisin d'un onglet fermé
            // disparaîtrait avant de reparaître à sa nouvelle place.
            .background(selectionFill, in: .rect(cornerRadius: 6))
            .overlay {
                if workspace.renaming == item {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(accent.color, lineWidth: 1)
                }
            }
            .contentShape(.rect(cornerRadius: 6))
            .onTapGesture(perform: show)
            // En plus du clic simple : le double-clic ne retarde pas la sélection.
            .simultaneousGesture(TapGesture(count: 2).onEnded { workspace.startRenaming(item) })
            .onRightClick(isEnabled: workspace.renaming != item) { PopupMenu.show(menu, at: $0) }
            // Pendant un glisser, les onglets passent sous la souris en changeant de place :
            // sans ça, leur croix clignote au passage.
            .onHover { hovering in
                guard !isDragging else { return }
                withAnimation(Ink.feedback) { isHovered = hovering }
            }
            .onChange(of: isDragging) { _, dragging in
                if dragging { isHovered = false }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(workspace.displayedTitle(of: item))
            .accessibilityValue(workspace.statusText(of: item) ?? "")
            .accessibilityAddTraits(highlight == .none ? .isButton : [.isButton, .isSelected])
            .accessibilityAction(.default, show)
            // Le menu du clic droit est une fenêtre à part, hors de portée de VoiceOver.
            .accessibilityActions {
                ForEach(Array(menuActions.enumerated()), id: \.offset) { _, action in
                    Button(action.title, action: action.run)
                }
            }
    }

    private func show() {
        switch item {
        case let .tab(tab): workspace.select(tab)
        case let .pane(pane): workspace.focus(pane)
        }
    }

    /// Un onglet seul, un groupe, ou un terminal d'un groupe : les mots du menu suivent.
    private var isGroup: Bool {
        if case let .tab(tab) = item { return workspace.layout.isSplit(tab) }
        return false
    }

    /// Sans raccourcis affichés : ceux du menu agissent sur l'onglet actif, pas sur celui cliqué.
    private var menu: [MenuEntry] {
        let rename: TextKey = switch item {
        case .tab: isGroup ? .renameGroup : .renameTab
        case .pane: .renameTerminal
        }
        var entries: [MenuEntry] = [.item(L10n.text(rename)) { workspace.startRenaming(item) }]
        if workspace.label(of: item)?.title != nil {
            entries.append(.item(L10n.text(.resetTabName)) { workspace.resetTitle(item) })
        }
        let color = workspace.label(of: item)?.color
        let colors: [MenuEntry] = TabColor.allCases.map { choice in
            .item(choice.name, swatch: choice.color, checked: color == choice) { workspace.setColor(choice, of: item) }
        }
        entries.append(.submenu(L10n.text(.tabColor), colors + [.separator, .item(L10n.text(.noColor), checked: color == nil) {
            workspace.setColor(nil, of: item)
        }]))
        // Comme les couleurs : les choix, puis celle par défaut.
        let icon = workspace.icon(of: item)
        let icons: [MenuEntry] = TabIcon.allCases.filter { $0 != .terminal }.map { choice in
            .item(choice.name, symbol: choice.symbol, checked: icon == choice) { workspace.setIcon(choice, of: item) }
        }
        entries.append(.submenu(L10n.text(.tabIcon), icons + [.separator, .item(
            TabIcon.terminal.name, symbol: TabIcon.terminal.symbol, checked: icon == .terminal
        ) {
            workspace.setIcon(.terminal, of: item)
        }]))
        return entries + [.separator] + structureEntries
    }

    /// Ce qui touche à la place de l'onglet, du groupe ou du terminal. Diviser se fait depuis un
    /// terminal, pas depuis un groupe qui en a plusieurs.
    private var structureEntries: [MenuEntry] {
        switch item {
        case let .tab(tab) where isGroup:
            var entries: [MenuEntry] = []
            if isVertical {
                let isCollapsed = workspace.collapsed.contains(tab)
                entries.append(.item(L10n.text(isCollapsed ? .expandGroup : .collapseGroup)) { workspace.toggleCollapsed(tab) })
            }
            entries.append(.item(L10n.text(.ungroup)) { workspace.separate(tab) })
            return entries + closeEntries(tab, close: .closeGroup)
        case let .tab(tab):
            let pane = workspace.layout.splits[tab]?.focused
            return [
                .item(L10n.text(.splitRight)) { workspace.split(.horizontal, from: pane) },
                .item(L10n.text(.splitDown)) { workspace.split(.vertical, from: pane) },
            ] + closeEntries(tab, close: .closeTab)
        case let .pane(pane):
            return [
                .item(L10n.text(.splitRight)) { workspace.split(.horizontal, from: pane) },
                .item(L10n.text(.splitDown)) { workspace.split(.vertical, from: pane) },
                .item(L10n.text(.zoomSplit), checked: workspace.zoomedPane == pane) { workspace.toggleZoom(pane) },
                .item(L10n.text(.leaveGroup)) { workspace.detach(pane) },
                .separator,
                .item(L10n.text(.closeTerminal)) { workspace.closePane(pane) },
            ]
        }
    }

    private func closeEntries(_ tab: UUID, close: TextKey) -> [MenuEntry] {
        [
            .separator,
            .item(L10n.text(close)) { workspace.close(tab) },
            .item(L10n.text(.closeOtherTabs), enabled: !workspace.layout.tabs(besides: tab).isEmpty) { workspace.closeOthers(of: tab) },
            .item(L10n.text(isVertical ? .closeTabsBelow : .closeTabsToTheRight), enabled: !workspace.layout.tabs(after: tab).isEmpty) {
                workspace.closeAfter(tab)
            },
        ]
    }

    /// Le menu à plat, pour VoiceOver : les choix de couleur et d'icône y entrent un par un.
    private var menuActions: [(title: String, run: () -> Void)] {
        menu.flatMap { entry -> [(title: String, run: () -> Void)] in
            guard case let .action(action) = entry, action.isEnabled else { return [] }
            guard let submenu = action.submenu else { return [(action.title, action.run)] }
            return submenu.compactMap { choice in
                guard case let .action(choice) = choice else { return nil }
                return ("\(action.title) : \(choice.title)", choice.run)
            }
        }
    }

    /// Une couleur choisie teinte tout l'onglet, plus fort quand il est affiché.
    private var selectionFill: Color {
        if let color = workspace.label(of: item)?.color?.color {
            return color.opacity(highlight == .full ? 0.28 : highlight == .half ? 0.18 : 0.12)
        }
        return highlight == .full ? Ink.selection : highlight == .half ? Ink.hover : .clear
    }

    /// Posé sur `selectionFill`, il monte l'onglet survolé d'un cran.
    private var hoverFill: Color {
        guard isHovered, highlight != .full else { return .clear }
        return workspace.label(of: item)?.color?.color.opacity(highlight == .half ? 0.12 : 0.07) ?? Ink.hover
    }
}
