import BrumeCore
import SwiftUI

struct SearchCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Divider()
            Button(L10n.text(.find)) { workspace?.toggleSearch() }
                .keyboardShortcut("f")
            Button(L10n.text(.findNext)) { workspace?.focusedSearch?.next() }
                .keyboardShortcut("g")
                .disabled(workspace?.focusedSearch == nil)
            Button(L10n.text(.findPrevious)) { workspace?.focusedSearch?.previous() }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(workspace?.focusedSearch == nil)
            Button(L10n.text(.findSelection)) { workspace?.searchSelection() }
                .keyboardShortcut("e")
        }
    }
}
