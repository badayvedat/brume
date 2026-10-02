import SwiftUI

@main
struct BrumeApp: App {
    var body: some Scene {
        WindowGroup {
            TerminalScreen()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 560)
    }
}
