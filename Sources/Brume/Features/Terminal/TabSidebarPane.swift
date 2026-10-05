import BrumeCore
import SwiftUI

/// Un split d'un groupe déplié, sous son en-tête, avec les gestes d'un onglet : la fenêtre en
/// miniature montre où il s'affiche.
struct TabSidebarPane: View {
    static let height: CGFloat = 26

    let pane: UUID
    let tab: UUID
    let workspace: TerminalWorkspace
    let isDragging: Bool

    @State private var isHovered = false

    var body: some View {
        let layout = workspace.layout
        let isFocused = layout.selectedTab == tab && layout.focusedPane == pane
        let title = workspace.displayedTitle(of: .pane(pane))
        HStack(spacing: 8) {
            if let tree = layout.splits[tab]?.tree {
                ZoneMap(tree: tree, pane: pane, isFocused: isFocused)
            }
            if let icon = workspace.label(of: .pane(pane))?.icon {
                TabIconView(symbol: icon.symbol, number: nil, isLit: isFocused || isHovered)
            }
            Group {
                if workspace.renaming == .pane(pane) {
                    TabRenameField(title: title) { workspace.finishRenaming(.pane(pane), input: $0, displayed: $1) }
                } else {
                    TabTitleText(title: title, size: 12)
                        .foregroundStyle(isFocused || isHovered ? Ink.text : Ink.muted)
                }
            }
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            .tabTooltip(.pane(pane), in: workspace, isDragging: isDragging)
            TabStatus(
                isHovered: isHovered, progress: workspace.paneProgress[pane], activity: workspace.paneActivity[pane],
                closeLabel: L10n.text(.closeTerminal)
            ) {
                workspace.closePane(pane)
            }
        }
        // Sous le titre du groupe, pas sous son icône.
        .padding(.leading, 30)
        .padding(.trailing, 4)
        .frame(height: Self.height)
        .tabBehavior(.pane(pane), in: workspace, highlight: isFocused ? .full : .none, isHovered: $isHovered, isDragging: isDragging, isVertical: true)
    }
}
