import SwiftUI

struct TerminalScreen: View {
    /// Toute la fenêtre : barres d'onglets, terminaux et glissés partagent cet espace.
    static let space = "terminal-screen"

    @State private var workspace = TerminalWorkspace()
    @State private var titlebar = WindowTitlebar()
    @State private var commandKey = CommandKeyHold()

    var body: some View {
        TerminalSplitView(workspace: workspace, titlebar: titlebar, showsNumbers: commandKey.isHeld)
            .coordinateSpace(.named(Self.space))
            .ignoresSafeArea(.container, edges: .top)
            .modifier(TerminalWindowChrome(state: workspace.focused, customTitle: workspace.title(of: workspace.focusedID)))
            .focusedSceneValue(\.terminalWorkspace, workspace)
            .background(WindowReader {
                workspace.attach(to: $0)
                titlebar.attach(to: $0)
            })
            .onAppear { workspace.focus(workspace.focusedID) }
    }
}
