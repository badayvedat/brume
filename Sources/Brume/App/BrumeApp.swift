import SwiftUI

@main
struct BrumeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                // Sans ce fond explicite, SwiftUI peint un fond opaque par-dessus le flou.
                .containerBackground(.ultraThinMaterial, for: .window)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 560)
    }
}
