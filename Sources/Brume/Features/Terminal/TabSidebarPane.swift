import BrumeCore
import SwiftUI

/// Un split d'un groupe déplié, sous son en-tête : la fenêtre en miniature montre où il s'affiche.
struct TabSidebarPane: View {
    let pane: UUID
    let tab: UUID
    let workspace: TerminalWorkspace

    @State private var isHovered = false

    var body: some View {
        let layout = workspace.layout
        let isFocused = layout.selectedTab == tab && layout.focusedPane == pane
        HStack(spacing: 8) {
            if let tree = layout.splits[tab]?.tree {
                ZoneMap(tree: tree, pane: pane, isFocused: isFocused)
            }
            Text(workspace.paneTitle(pane))
                .font(.system(size: 12))
                .animation(nil) { $0.foregroundStyle(isFocused || isHovered ? Ink.text : Ink.muted) }
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .leading)
            TabStatus(isHovered: isHovered, progress: workspace.paneProgress[pane], hasActivity: workspace.activity.contains(pane)) {
                workspace.closePane(pane)
            }
        }
        // Sous le titre du groupe, pas sous son icône.
        .padding(.leading, 30)
        .padding(.trailing, 4)
        .frame(height: 26)
        .animation(Ink.feedback) { $0.background(isHovered && !isFocused ? Ink.hover : .clear, in: .rect(cornerRadius: 6)) }
        .animation(nil) { $0.background(isFocused ? Ink.selection : .clear, in: .rect(cornerRadius: 6)) }
        .contentShape(.rect(cornerRadius: 6))
        .onTapGesture { workspace.focus(pane) }
        .onRightClick { PopupMenu.show(menu, at: $0) }
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(workspace.paneTitle(pane))
        .accessibilityAddTraits(isFocused ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(.default) { workspace.focus(pane) }
        .accessibilityAction(named: L10n.text(.moveToNewTab)) { workspace.detach(pane) }
        .accessibilityAction(named: L10n.text(.closeSplit)) { workspace.closePane(pane) }
    }

    private var menu: [MenuEntry] {
        [
            .item(L10n.text(.moveToNewTab)) { workspace.detach(pane) },
            .separator,
            .item(L10n.text(.closeSplit)) { workspace.closePane(pane) },
        ]
    }
}
