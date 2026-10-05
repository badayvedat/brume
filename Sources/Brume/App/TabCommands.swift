import BrumeCore
import SwiftUI

struct TabCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace
    @Environment(\.openWindow) private var openWindow
    let settings: SettingsStore

    var body: some Commands {
        // Posé dès le lancement, avant toute fenêtre : un dossier ouvert dans Brume fermé en ouvre une.
        let _ = TerminalWorkspace.openNewWindow = { [openWindow] in openWindow(id: BrumeApp.terminalWindowID) }
        CommandGroup(after: .newItem) {
            // Sans fenêtre active : dans celle ramenée devant, sinon dans une neuve, comme ⌘N.
            Button(L10n.text(.newTab)) {
                guard let target = workspace ?? TerminalWorkspace.front() else { return openWindow(id: BrumeApp.terminalWindowID) }
                target.showingTerminals { $0.newTab() }
            }
            .keyboardShortcut(settings.keyboardShortcut(.newTab))
            Button(L10n.text(workspace?.isSplit == true ? .renameGroup : .renameTab)) { workspace?.showingTerminals { $0.startRenaming() } }
                .keyboardShortcut(settings.keyboardShortcut(.renameTab))
        }
        CommandGroup(before: .windowArrangement) {
            Button(L10n.text(.previousTab)) { workspace?.showingTerminals { $0.selectPrevious() } }
                .keyboardShortcut(settings.keyboardShortcut(.previousTab))
            Button(L10n.text(.nextTab)) { workspace?.showingTerminals { $0.selectNext() } }
                .keyboardShortcut(settings.keyboardShortcut(.nextTab))
            ForEach(1 ..< 9) { number in
                Button("\(L10n.text(.tab)) \(number)") { workspace?.showingTerminals { $0.select(number: number) } }
                    .keyboardShortcut(settings.tabShortcut(number))
            }
            Button(L10n.text(.lastTab)) { workspace?.showingTerminals { $0.select(number: 9) } }
                .keyboardShortcut(settings.tabShortcut(9))
            Divider()
            Button(L10n.text(.resetWindow)) { workspace?.askReset() }
                .keyboardShortcut(settings.keyboardShortcut(.resetWindow))
            Divider()
        }
    }
}
