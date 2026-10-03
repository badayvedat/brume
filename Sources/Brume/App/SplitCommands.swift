import BrumeCore
import SwiftUI

struct SplitCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Divider()
            Button(L10n.text(.splitRight)) { workspace?.split(.horizontal) }
                .keyboardShortcut("d")
            Button(L10n.text(.splitDown)) { workspace?.split(.vertical) }
                .keyboardShortcut("d", modifiers: [.command, .shift])
        }
        CommandGroup(before: .windowArrangement) {
            Button("Split précédent") { workspace?.focusPrevious() }
                .keyboardShortcut("[")
            Button("Split suivant") { workspace?.focusNext() }
                .keyboardShortcut("]")
            Button("Split à gauche") { workspace?.focus(toward: .left) }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
            Button("Split à droite") { workspace?.focus(toward: .right) }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
            Button("Split au-dessus") { workspace?.focus(toward: .up) }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])
            Button("Split en dessous") { workspace?.focus(toward: .down) }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])
            Button("Égaliser les splits") { workspace?.equalizeSplits() }
                .keyboardShortcut("=", modifiers: [.command, .control])
            Divider()
        }
    }
}
