import BrumeCore
import SwiftUI

struct TabCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(L10n.text(.newTab)) { workspace?.newTab() }
                .keyboardShortcut("t")
            Button(L10n.text(workspace?.isSplit == true ? .renameGroup : .renameTab)) { workspace?.startRenaming() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
        }
        CommandGroup(before: .windowArrangement) {
            Button(L10n.text(.previousTab)) { workspace?.selectPrevious() }
                .keyboardShortcut("[", modifiers: [.command, .shift])
            Button(L10n.text(.nextTab)) { workspace?.selectNext() }
                .keyboardShortcut("]", modifiers: [.command, .shift])
            ForEach(1 ..< 9) { number in
                Button("\(L10n.text(.tab)) \(number)") { workspace?.select(number: number) }
                    .keyboardShortcut(KeyEquivalent(Character("\(number)")))
            }
            Button(L10n.text(.lastTab)) { workspace?.select(number: 9) }
                .keyboardShortcut("9")
            Divider()
        }
    }
}
