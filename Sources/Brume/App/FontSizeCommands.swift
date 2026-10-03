import BrumeCore
import SwiftUI

// Le moteur traite déjà ces raccourcis quand le terminal a le focus (y compris
// Cmd+= des claviers sans touche plus) : le menu sert depuis la barre de recherche.
struct FontSizeCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button(L10n.text(.increaseFontSize)) { workspace?.changeFontSize(.increase) }
                .keyboardShortcut("+")
            Button(L10n.text(.decreaseFontSize)) { workspace?.changeFontSize(.decrease) }
                .keyboardShortcut("-")
            Button(L10n.text(.resetFontSize)) { workspace?.changeFontSize(.reset) }
                .keyboardShortcut("0")
            Button(L10n.text(.resetAllSizes)) { workspace?.resetSizes() }
                .keyboardShortcut("0", modifiers: [.command, .control])
            Divider()
        }
    }
}
