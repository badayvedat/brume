import BrumeCore
import SwiftUI

/// Remplace le « Fermer » de SwiftUI, qui fermerait toute la fenêtre : comme Ghostty, Cmd+W ferme
/// le terminal, Option+Cmd+W l'onglet ou le groupe entier.
struct CloseCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace
    let settings: SettingsStore

    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button(L10n.text(.close)) { workspace?.closeFocused() }
                .keyboardShortcut(settings.keyboardShortcut(.closeTerminal))
            Button(L10n.text(workspace?.isSplit == true ? .closeGroup : .closeTab)) { workspace?.showingTerminals { $0.closeSelectedTab() } }
                .keyboardShortcut(settings.keyboardShortcut(.closeTab))
            Button(L10n.text(.closeWindow)) { workspace?.closeWindow() }
                .keyboardShortcut("w", modifiers: [.command, .shift])
        }
    }
}
