import BrumeCore
import SwiftUI

struct TabCommands: Commands {
    @FocusedValue(\.terminalTabs) private var tabs

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(L10n.text(.newTab)) { tabs?.newTab() }
                .keyboardShortcut("t")
        }
        CommandGroup(before: .windowArrangement) {
            Button(L10n.text(.previousTab)) { tabs?.selectPrevious() }
                .keyboardShortcut("[", modifiers: [.command, .shift])
            Button(L10n.text(.nextTab)) { tabs?.selectNext() }
                .keyboardShortcut("]", modifiers: [.command, .shift])
            ForEach(1 ..< 9) { number in
                Button("\(L10n.text(.tab)) \(number)") { tabs?.select(number: number) }
                    .keyboardShortcut(KeyEquivalent(Character("\(number)")))
            }
            Button(L10n.text(.lastTab)) { tabs?.select(number: 9) }
                .keyboardShortcut("9")
            Divider()
        }
    }
}
