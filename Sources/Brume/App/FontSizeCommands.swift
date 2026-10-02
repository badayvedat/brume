import SwiftUI

// Le moteur traite déjà ces raccourcis quand le terminal a le focus (y compris
// Cmd+= des claviers sans touche plus) : le menu sert depuis la barre de recherche.
struct FontSizeCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Agrandir le texte") { workspace?.changeFontSize(.increase) }
                .keyboardShortcut("+")
            Button("Réduire le texte") { workspace?.changeFontSize(.decrease) }
                .keyboardShortcut("-")
            Button("Taille réelle") { workspace?.changeFontSize(.reset) }
                .keyboardShortcut("0")
            Divider()
        }
    }
}
