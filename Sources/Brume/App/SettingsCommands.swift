import BrumeCore
import SwiftUI

/// « Réglages… » ouvre la page de réglages dans la fenêtre active, pas une fenêtre à part :
/// ils baignent dans le même verre que les terminaux. Sans fenêtre active, dans celle ramenée
/// devant, sinon dans une neuve.
struct SettingsCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("\(L10n.text(.settings))…") {
                if let target = workspace ?? TerminalWorkspace.front() { return target.showSettings() }
                TerminalWorkspace.whenOpened { $0.showSettings() }
                openWindow(id: BrumeApp.terminalWindowID)
            }
            .keyboardShortcut(",")
        }
    }
}
