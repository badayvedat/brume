import SwiftUI

@main
struct BrumeApp: App {
    init() {
        // Le shell hérite de cette variable : le patch zsh y trouve les greffons embarqués.
        if let resources = Bundle.main.resourcePath {
            setenv("BRUME_RESOURCES_DIR", resources, 1)
        }
    }

    static let terminalWindowID = "terminal"

    var body: some Scene {
        WindowGroup(id: Self.terminalWindowID) {
            TerminalScreen()
                .background(WindowReader { WindowTabs.adopt($0) })
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 560)
        .commands {
            CommandGroup(after: .newItem) {
                NewTabButton()
            }
            SplitCommands()
        }
    }
}
