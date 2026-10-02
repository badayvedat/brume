import SwiftUI

struct TerminalScreen: View {
    @State private var workspace = TerminalWorkspace()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TerminalSplitView(workspace: workspace)
            .modifier(TerminalWindowChrome(state: workspace.focused))
            .focusedSceneValue(\.terminalWorkspace, workspace)
            .onAppear {
                workspace.onEmpty = { dismiss() }
                workspace.focus(workspace.focusedID)
            }
    }
}
