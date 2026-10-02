import AppKit
import SwiftUI

// SwiftUI n'ouvre que des fenêtres : pour Cmd+T, la suivante rejoint en onglet
// celle qui avait le focus, comme les onglets natifs de Ghostty.
@MainActor
enum WindowTabs {
    private static weak var pendingParent: NSWindow?

    static func prepareNewTab() {
        pendingParent = NSApp.keyWindow
    }

    static func adopt(_ window: NSWindow) {
        guard let parent = pendingParent, parent !== window else { return }
        pendingParent = nil
        parent.addTabbedWindow(window, ordered: .above)
        window.makeKeyAndOrderFront(nil)
    }
}

struct NewTabButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Nouvel onglet") {
            WindowTabs.prepareNewTab()
            openWindow(id: BrumeApp.terminalWindowID)
        }
        .keyboardShortcut("t")
    }
}
