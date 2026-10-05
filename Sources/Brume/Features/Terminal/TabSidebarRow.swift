import BrumeCore
import SwiftUI

/// Un onglet dans la barre latérale, sur toute la largeur. Divisé, il devient l'en-tête d'un
/// groupe qui se déplie sur ses splits.
struct TabSidebarRow: View {
    static let height: CGFloat = 30

    let tab: UUID
    let workspace: TerminalWorkspace
    let isDragging: Bool
    /// Le chiffre de son raccourci, montré tant que Cmd est tenu.
    let number: Int?

    @State private var isHovered = false

    var body: some View {
        let layout = workspace.layout
        let isSelected = layout.selectedTab == tab
        let isGroup = layout.isSplit(tab)
        let isExpanded = isGroup && !workspace.collapsed.contains(tab)
        let title = workspace.displayedTitle(of: .tab(tab))
        HStack(spacing: 8) {
            TabIconView(symbol: workspace.symbol(of: tab), number: number, isLit: isSelected || isHovered)
            Group {
                if workspace.renaming == .tab(tab) {
                    TabRenameField(title: title) { workspace.finishRenaming(.tab(tab), input: $0, displayed: $1) }
                } else {
                    TabTitleText(title: title, size: 13)
                        .foregroundStyle(isSelected || isHovered ? Ink.text : Ink.muted)
                }
            }
            .font(.system(size: 13))
            .frame(maxWidth: .infinity, alignment: .leading)
            .tabTooltip(.tab(tab), in: workspace, isDragging: isDragging)
            TabStatus(
                isHovered: isHovered, progress: workspace.progress(of: tab), hasActivity: workspace.hasActivity(tab),
                // Ni sur un groupe, où elle fermerait tous ses terminaux, ni sur le seul onglet, qui
                // se ferme avec la fenêtre par le bouton rouge.
                onClose: isGroup || layout.tabs.count == 1 ? nil : { workspace.close(tab) }
            )
            if isGroup {
                FoldButton(isExpanded: isExpanded) { workspace.toggleCollapsed(tab) }
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(height: Self.height)
        // Déplié, le plein va au split actif, dessous.
        .tabBehavior(
            .tab(tab), in: workspace, highlight: isSelected ? (isExpanded ? .half : .full) : .none,
            isHovered: $isHovered, isDragging: isDragging, isVertical: true
        )
        .accessibilityAction(named: L10n.text(isExpanded ? .collapseGroup : .expandGroup)) { workspace.toggleCollapsed(tab) }
    }
}

/// Le chevron d'un groupe : il le replie ou le déplie.
private struct FoldButton: View {
    let isExpanded: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image("chevron.right", size: 10, weight: .semibold)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .foregroundStyle(isHovered ? Ink.text : Ink.muted)
                .frame(width: 20, height: 20)
                .background(isHovered ? Ink.selection : .clear, in: .rect(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(isExpanded ? .collapseGroup : .expandGroup))
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
        .animation(Ink.slide, value: isExpanded)
    }
}
