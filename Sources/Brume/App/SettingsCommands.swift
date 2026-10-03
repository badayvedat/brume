import BrumeCore
import SwiftUI

/// « Réglages… » ouvre la page de réglages dans la fenêtre active, pas une fenêtre à part :
/// ils baignent dans le même verre que les terminaux.
struct SettingsCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("\(L10n.text(.settings))…") { workspace?.showSettings() }
                .keyboardShortcut(",")
                .disabled(workspace == nil)
        }
    }
}
