import GhosttyTerminal
import SwiftUI

struct TerminalSplitView: View {
    let workspace: TerminalWorkspace

    var body: some View {
        GeometryReader { geometry in
            let bounds = CGRect(origin: .zero, size: geometry.size)
            let frames = workspace.tree.frames(in: bounds)
            // Tous les volets au même niveau, rangés par identifiant : SwiftUI garde chaque
            // vue quand l'arbre change. Une vue recréée tuerait le shell qu'elle porte.
            ZStack(alignment: .topLeading) {
                ForEach(workspace.tree.panes, id: \.self) { id in
                    if let state = workspace.states[id], let frame = frames[id] {
                        TerminalPane(
                            state: state,
                            dimmed: workspace.isSplit && id != workspace.focusedID,
                            onFocus: { workspace.didFocus(id) }
                        )
                        .frame(width: frame.width, height: frame.height)
                        .offset(x: frame.minX, y: frame.minY)
                    }
                }
                ForEach(Array(workspace.tree.dividers(in: bounds).enumerated()), id: \.offset) { _, line in
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(width: max(line.width, 1), height: max(line.height, 1))
                        .offset(x: line.minX, y: line.minY)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

private struct TerminalPane: View {
    @ObservedObject var state: TerminalViewState
    let dimmed: Bool
    let onFocus: () -> Void

    var body: some View {
        TerminalSurfaceView(context: state)
            // Comme Ghostty : le volet inactif est légèrement assombri.
            .overlay {
                if dimmed {
                    Color.black.opacity(0.3).allowsHitTesting(false)
                }
            }
            .onChange(of: state.isFocused) { _, isFocused in
                if isFocused { onFocus() }
            }
    }
}

/// Titre et couleur de la fenêtre, pris sur le terminal qui a le focus.
struct TerminalWindowChrome: ViewModifier {
    @ObservedObject var state: TerminalViewState

    func body(content: Content) -> some View {
        content
            .navigationTitle(state.title)
            // La barre de titre prend la couleur du terminal, comme dans Ghostty.
            .containerBackground(Color(state.backgroundColor), for: .window)
    }
}
