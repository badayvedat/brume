import SwiftUI

@main
struct BrumeApp: App {
    init() {
        // Le shell hérite de cette variable : le patch zsh y trouve les greffons embarqués.
        if let resources = Bundle.main.resourcePath {
            setenv("BRUME_RESOURCES_DIR", resources, 1)
        }
    }

    var body: some Scene {
        WindowGroup {
            TerminalScreen()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 560)
    }
}
