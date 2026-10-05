import BrumeCore
import SwiftUI

struct SearchCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Divider()
            Button(L10n.text(.find)) { workspace?.showingTerminals { $0.toggleSearch() } }
                .keyboardShortcut("f")
            Button(L10n.text(.findNext)) { workspace?.showingTerminals { $0.focusedSearch?.next() } }
                .keyboardShortcut("g")
                .disabled(workspace?.focusedSearch == nil)
            Button(L10n.text(.findPrevious)) { workspace?.showingTerminals { $0.focusedSearch?.previous() } }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(workspace?.focusedSearch == nil)
            Button(L10n.text(.findSelection)) { workspace?.showingTerminals { $0.searchSelection() } }
                .keyboardShortcut("e")
        }
    }
}
