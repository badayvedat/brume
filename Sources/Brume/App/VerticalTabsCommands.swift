import BrumeCore
import SwiftUI

/// ⌃⌘S, le raccourci de macOS pour la barre latérale (Finder, Mail, Notes) : il passe des onglets
/// en haut à la barre latérale, dans toutes les fenêtres.
struct VerticalTabsCommands: Commands {
    static let shortcut = "⌃⌘S"

    let settings: SettingsStore

    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Toggle(L10n.text(.verticalTabs), isOn: Binding(
                get: { settings.verticalTabs.isOn },
                set: { settings.verticalTabs.isOn = $0 }
            ))
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
    }
}
