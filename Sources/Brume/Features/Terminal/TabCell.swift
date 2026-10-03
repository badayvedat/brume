import BrumeCore
import SwiftUI

/// Un onglet de la barre du haut. Divisé, il porte l'icône d'un split et le titre de ses terminaux.
struct TabCell: View {
    let tab: UUID
    let workspace: TerminalWorkspace
    let isDragging: Bool
    /// Le chiffre de son raccourci, montré tant que Cmd est tenu.
    let number: Int?

    @State private var isHovered = false

    var body: some View {
        let isSelected = workspace.layout.selectedTab == tab
        let title = workspace.displayedTitle(of: tab)
        HStack(spacing: 4) {
            TabIconView(symbol: workspace.symbol(of: tab), number: number, isLit: isSelected || isHovered)
                .padding(.trailing, 4)
            Group {
                if workspace.renamingID == tab {
                    TabRenameField(title: title) { workspace.finishRenaming(tab, input: $0, displayed: title) }
                } else {
                    Text(title)
                        .animation(nil) { $0.foregroundStyle(isSelected || isHovered ? Ink.text : Ink.muted) }
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            TabStatus(isHovered: isHovered, progress: workspace.progress(of: tab), hasActivity: workspace.hasActivity(tab)) {
                workspace.close(tab)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(height: 30)
        .tabBehavior(tab, in: workspace, highlight: isSelected ? .full : .none, isHovered: $isHovered, isDragging: isDragging, isVertical: false)
    }
}

/// L'icône de l'onglet, et à sa place le numéro de son raccourci tant que Cmd est tenu, comme Muxy.
struct TabIconView: View {
    let symbol: String
    let number: Int?
    let isLit: Bool

    @Environment(\.accent) private var accent

    var body: some View {
        Group {
            if let number {
                Text("\(number)")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(accent.color, in: .rect(cornerRadius: 4))
            } else {
                SystemSymbol.image(symbol, size: 12)
                    .animation(nil) { $0.foregroundStyle(isLit ? Ink.text : Ink.muted) }
            }
        }
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}
