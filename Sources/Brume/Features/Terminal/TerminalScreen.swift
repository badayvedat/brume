import SwiftUI

struct TerminalScreen: View {
    @State private var workspace = TerminalWorkspace()

    var body: some View {
        TerminalSplitView(workspace: workspace)
            .modifier(TerminalWindowChrome(state: workspace.focused))
            .focusedSceneValue(\.terminalWorkspace, workspace)
            .background(WindowReader { workspace.attach(to: $0) })
            .onAppear { workspace.focus(workspace.focusedID) }
    }
}
