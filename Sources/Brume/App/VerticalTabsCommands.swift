import BrumeCore
import SwiftUI

/// Passe des onglets en haut à la barre latérale, dans toutes les fenêtres.
struct VerticalTabsCommands: Commands {
    let settings: SettingsStore

    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Toggle(L10n.text(.verticalTabs), isOn: Binding(
                get: { settings.verticalTabs.isOn },
                set: { settings.verticalTabs.isOn = $0 }
            ))
            .keyboardShortcut(settings.keyboardShortcut(.verticalTabs))
        }
    }
}
