import SwiftUI

struct TerminalScreen: View {
    @State private var tabs = TerminalTabs()

    var body: some View {
        VStack(spacing: 0) {
            TabBar(tabs: tabs)
            // Tous les onglets restent montés, les cachés transparents : retirer la vue
            // d'un terminal tuerait son shell.
            ZStack {
                ForEach(tabs.tabs) { workspace in
                    let isSelected = workspace === tabs.selected
                    TerminalSplitView(workspace: workspace)
                        .opacity(isSelected ? 1 : 0)
                        .allowsHitTesting(isSelected)
                        .accessibilityHidden(!isSelected)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .modifier(TerminalWindowChrome(state: tabs.selected.focused))
        .focusedSceneValue(\.terminalTabs, tabs)
        .focusedSceneValue(\.terminalWorkspace, tabs.selected)
        .background(WindowReader { tabs.attach(to: $0) })
        .onAppear { tabs.selected.focus(tabs.selected.focusedID) }
    }
}
