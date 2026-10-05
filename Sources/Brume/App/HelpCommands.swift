import AppKit
import BrumeCore
import SwiftUI

/// Remplace « Aide Brume », qui mène à une aide qui n'existe pas.
struct HelpCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button(L10n.text(.brumeOnGitHub)) { NSWorkspace.shared.open(Links.repository) }
            Button(L10n.text(.reportIssue)) { NSWorkspace.shared.open(Links.newIssue) }
        }
    }
}
