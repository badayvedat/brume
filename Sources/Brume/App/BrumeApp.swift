import SwiftUI

@main
struct BrumeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var session = SessionStore()

    init() {
        SystemSymbol.preload()
        // Le shell hérite de cette variable : le patch zsh y trouve les greffons embarqués.
        if let resources = Bundle.main.resourcePath {
            setenv("BRUME_RESOURCES_DIR", resources, 1)
        }
    }

    static let terminalWindowID = "terminal"

    var body: some Scene {
        WindowGroup(id: Self.terminalWindowID) {
            TerminalScreen()
                .environment(session)
        }
        // Brume rouvre lui-même ses fenêtres (`SessionStore`) : macOS en rouvrirait en double.
        .restorationBehavior(.disabled)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 500)
        .commands {
            TabCommands()
            CloseCommands()
            SplitCommands()
            SearchCommands()
            FontSizeCommands()
        }
    }
}
