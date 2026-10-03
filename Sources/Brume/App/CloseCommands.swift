import BrumeCore
import SwiftUI

/// Remplace le « Fermer » de SwiftUI, qui fermerait toute la fenêtre : Cmd+W ferme le volet, comme Ghostty.
struct CloseCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button(L10n.text(.close)) { workspace?.closeFocused() }
                .keyboardShortcut("w")
            Button(L10n.text(.closeWindow)) { workspace?.closeWindow() }
                .keyboardShortcut("w", modifiers: [.command, .shift])
        }
    }
}
