import BrumeCore
import SwiftUI

/// « Rechercher les mises à jour… » sous « À propos de Brume », comme les autres apps Sparkle.
struct UpdateCommands: Commands {
    let updater: UpdaterStore

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            CheckForUpdatesItem(updater: updater)
        }
    }
}

/// Une vue plutôt que le bouton seul : elle suit `canCheck` quand il change.
private struct CheckForUpdatesItem: View {
    let updater: UpdaterStore

    var body: some View {
        Button("\(L10n.text(.checkForUpdates))…", action: updater.checkForUpdates)
            .disabled(!updater.canCheck)
    }
}
