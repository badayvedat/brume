import BrumeCore
import GhosttyTerminal
import SwiftUI

/// En onglets verticaux, le haut de la fenêtre à droite de la barre latérale, comme le fil
/// d'Ariane des réglages : l'onglet affiché et le dossier du split actif, puis les boutons.
struct TerminalHeader: View {
    /// Le terminal qui a le clavier.
    @ObservedObject var state: TerminalViewState
    let workspace: TerminalWorkspace
    let height: CGFloat

    var body: some View {
        let tab = workspace.layout.selectedTab
        let title = workspace.displayedTitle(of: tab)
        // Le `~` du shell, qui suit HOME : `NSHomeDirectory()` peut en différer.
        let home = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
        let folder = state.workingDirectory.map { TabTitle.folder($0, home: home) }
        HStack(spacing: 8) {
            SystemSymbol.image(workspace.symbol(of: tab), size: 12)
                .foregroundStyle(Ink.muted)
                .frame(width: 16)
            Text(title)
                .foregroundStyle(Ink.text)
            if let folder, folder != title {
                Text(folder)
                    .foregroundStyle(Ink.hint)
                    .truncationMode(.head)
            }
            Spacer(minLength: 12)
            BarButtons(workspace: workspace)
        }
        .font(.system(size: 13))
        .lineLimit(1)
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(height: height)
        .background { WindowDragArea() }
        .overlay(alignment: .bottom) { Ink.rule.frame(height: 1).allowsHitTesting(false) }
    }
}
