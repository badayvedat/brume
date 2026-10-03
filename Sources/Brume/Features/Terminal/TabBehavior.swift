import BrumeCore
import SwiftUI

/// La place d'un onglet dans ce qu'on voit : l'onglet affiché est plein ; un groupe déplié qui
/// l'est n'est qu'à mi-teinte, son split actif portant le plein.
enum TabHighlight {
    case none, half, full
}

extension View {
    /// Ce qu'un onglet fait pareil en haut et dans la barre latérale : fond teinté, cadre du
    /// renommage, clic, double-clic, clic droit, survol et accessibilité.
    func tabBehavior(
        _ tab: UUID, in workspace: TerminalWorkspace, highlight: TabHighlight, isHovered: Binding<Bool>, isDragging: Bool, isVertical: Bool
    ) -> some View {
        modifier(TabBehavior(id: tab, workspace: workspace, highlight: highlight, isHovered: isHovered, isDragging: isDragging, isVertical: isVertical))
    }
}

private struct TabBehavior: ViewModifier {
    let id: UUID
    let workspace: TerminalWorkspace
    let highlight: TabHighlight
    @Binding var isHovered: Bool
    let isDragging: Bool
    let isVertical: Bool

    @Environment(\.accent) private var accent

    func body(content: Content) -> some View {
        content
            .animation(Ink.feedback) { $0.background(hoverFill, in: .rect(cornerRadius: 6)) }
            // L'onglet actif change d'un coup, comme dans un navigateur : en fondu, on en verrait
            // un instant deux, ou aucun, à chaque ouverture ou fermeture.
            .animation(nil) { $0.background(selectionFill, in: .rect(cornerRadius: 6)) }
            .overlay {
                if workspace.renamingID == id {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(accent.color, lineWidth: 1)
                }
            }
            .contentShape(.rect(cornerRadius: 6))
            .onTapGesture { workspace.select(id) }
            // En plus du clic simple : le double-clic ne retarde pas la sélection.
            .simultaneousGesture(TapGesture(count: 2).onEnded { workspace.startRenaming(id) })
            .onRightClick { PopupMenu.show(menu, at: $0) }
            // Pendant un glisser, les onglets passent sous la souris en changeant de place :
            // sans ça, leur croix clignote au passage.
            .onHover { hovering in
                if !isDragging { isHovered = hovering }
            }
            .onChange(of: isDragging) { _, dragging in
                if dragging { isHovered = false }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(workspace.displayedTitle(of: id))
            .accessibilityValue(accessibilityValue)
            .accessibilityAddTraits(highlight == .none ? .isButton : [.isButton, .isSelected])
            .accessibilityAction(.default) { workspace.select(id) }
            // Le menu du clic droit est une fenêtre à part, hors de portée de VoiceOver.
            .accessibilityAction(named: L10n.text(.renameTab)) { workspace.startRenaming(id) }
            .accessibilityAction(named: L10n.text(.resetTabName)) { workspace.resetTitle(id) }
            .accessibilityAction(named: L10n.text(.closeOtherTabs)) { workspace.closeOthers(of: id) }
            .accessibilityAction(named: L10n.text(isVertical ? .closeTabsBelow : .closeTabsToTheRight)) { workspace.closeAfter(id) }
            .accessibilityActions {
                ForEach(TabColor.allCases, id: \.self) { color in
                    Button("\(L10n.text(.tabColor)) : \(color.name)") { workspace.setColor(color, of: id) }
                }
                Button(L10n.text(.noColor)) { workspace.setColor(nil, of: id) }
                ForEach(TabIcon.allCases, id: \.self) { icon in
                    Button("\(L10n.text(.tabIcon)) : \(icon.name)") { workspace.setIcon(icon, of: id) }
                }
                if workspace.layout.isSplit(id) {
                    Button(L10n.text(.separateSplits)) { workspace.separate(id) }
                }
            }
            .accessibilityAction(named: L10n.text(.closeTab)) { workspace.close(id) }
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        if let progress = workspace.progress(of: id) {
            parts.append(progress.percent.map { (Double($0) / 100).formatted(.percent.locale(L10n.language.locale)) } ?? L10n.text(.inProgress))
        }
        if workspace.hasActivity(id) { parts.append(L10n.text(.newActivity)) }
        return parts.joined(separator: ", ")
    }

    /// Sans raccourcis affichés : ceux du menu agissent sur l'onglet actif, pas sur celui cliqué.
    private var menu: [MenuEntry] {
        var entries: [MenuEntry] = [.item(L10n.text(.renameTab)) { workspace.startRenaming(id) }]
        if workspace.title(of: id) != nil {
            entries.append(.item(L10n.text(.resetTabName)) { workspace.resetTitle(id) })
        }
        let color = workspace.color(of: id)
        let colors: [MenuEntry] = TabColor.allCases.map { choice in
            .item(choice.name, swatch: choice.color, checked: color == choice) { workspace.setColor(choice, of: id) }
        }
        entries.append(.submenu(L10n.text(.tabColor), colors + [.separator, .item(L10n.text(.noColor), checked: color == nil) {
            workspace.setColor(nil, of: id)
        }]))
        // Comme les couleurs : les choix, puis celle par défaut.
        let icon = workspace.icon(of: id)
        let icons: [MenuEntry] = TabIcon.allCases.filter { $0 != .terminal }.map { choice in
            .item(choice.name, symbol: choice.symbol, checked: icon == choice) { workspace.setIcon(choice, of: id) }
        }
        entries.append(.submenu(L10n.text(.tabIcon), icons + [.separator, .item(
            TabIcon.terminal.name, symbol: TabIcon.terminal.symbol, checked: icon == .terminal
        ) {
            workspace.setIcon(.terminal, of: id)
        }]))
        if workspace.layout.isSplit(id) {
            entries.append(.item(L10n.text(.separateSplits)) { workspace.separate(id) })
        }
        entries.append(.separator)
        entries.append(.item(L10n.text(.closeTab)) { workspace.close(id) })
        entries.append(.item(L10n.text(.closeOtherTabs), enabled: !workspace.layout.tabs(besides: id).isEmpty) {
            workspace.closeOthers(of: id)
        })
        entries.append(.item(L10n.text(isVertical ? .closeTabsBelow : .closeTabsToTheRight), enabled: !workspace.layout.tabs(after: id).isEmpty) {
            workspace.closeAfter(id)
        })
        return entries
    }

    /// Une couleur choisie teinte tout l'onglet, plus fort quand il est affiché.
    private var selectionFill: Color {
        if let color = workspace.color(of: id)?.color {
            return color.opacity(highlight == .full ? 0.28 : highlight == .half ? 0.18 : 0.12)
        }
        return highlight == .full ? Ink.selection : highlight == .half ? Ink.hover : .clear
    }

    /// Posé sur `selectionFill`, il monte l'onglet survolé d'un cran.
    private var hoverFill: Color {
        guard isHovered, highlight != .full else { return .clear }
        return workspace.color(of: id)?.color.opacity(highlight == .half ? 0.12 : 0.07) ?? Ink.hover
    }
}
