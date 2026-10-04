import BrumeCore
import SwiftUI

struct TabCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace
    let settings: SettingsStore

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(L10n.text(.newTab)) { workspace?.newTab() }
                .keyboardShortcut(settings.keyboardShortcut(.newTab))
            Button(L10n.text(workspace?.isSplit == true ? .renameGroup : .renameTab)) { workspace?.startRenaming() }
                .keyboardShortcut(settings.keyboardShortcut(.renameTab))
        }
        CommandGroup(before: .windowArrangement) {
            Button(L10n.text(.previousTab)) { workspace?.selectPrevious() }
                .keyboardShortcut(settings.keyboardShortcut(.previousTab))
            Button(L10n.text(.nextTab)) { workspace?.selectNext() }
                .keyboardShortcut(settings.keyboardShortcut(.nextTab))
            ForEach(1 ..< 9) { number in
                Button("\(L10n.text(.tab)) \(number)") { workspace?.select(number: number) }
                    .keyboardShortcut(settings.tabShortcut(number))
            }
            Button(L10n.text(.lastTab)) { workspace?.select(number: 9) }
                .keyboardShortcut(settings.tabShortcut(9))
            Divider()
        }
    }
}
