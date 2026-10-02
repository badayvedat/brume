import SwiftUI

struct SearchCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Divider()
            Button("Rechercher…") { workspace?.toggleSearch() }
                .keyboardShortcut("f")
            Button("Résultat suivant") { workspace?.focusedSearch?.next() }
                .keyboardShortcut("g")
                .disabled(workspace?.focusedSearch == nil)
            Button("Résultat précédent") { workspace?.focusedSearch?.previous() }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(workspace?.focusedSearch == nil)
            Button("Rechercher la sélection") { workspace?.searchSelection() }
                .keyboardShortcut("e")
        }
    }
}
