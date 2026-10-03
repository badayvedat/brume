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
            Button(L10n.text(.focusPreviousSplit)) { workspace?.focusPrevious() }
                .keyboardShortcut("[")
            Button(L10n.text(.focusNextSplit)) { workspace?.focusNext() }
                .keyboardShortcut("]")
            Button(L10n.text(.focusSplitLeft)) { workspace?.focus(toward: .left) }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
            Button(L10n.text(.focusSplitRight)) { workspace?.focus(toward: .right) }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
            Button(L10n.text(.focusSplitUp)) { workspace?.focus(toward: .up) }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])
            Button(L10n.text(.focusSplitDown)) { workspace?.focus(toward: .down) }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])
            Button(L10n.text(.equalizeSplits)) { workspace?.equalizeSplits() }
                .keyboardShortcut("=", modifiers: [.command, .control])
            // ⇧⌘↩ comme Ghostty.
            Toggle(L10n.text(.zoomSplit), isOn: Binding(
                get: { workspace?.zoomedPane != nil },
                set: { _ in workspace?.toggleZoom() }
            ))
            .keyboardShortcut(.return, modifiers: [.command, .shift])
            .disabled(workspace?.isSplit != true)
            Divider()
            // Gauche et haut avancent l'onglet, droite et bas le reculent : les flèches suivent la
            // barre d'onglets, en haut comme sur le côté.
            Button(L10n.text(.moveTabLeft)) { workspace?.moveSelectedTab(by: -1) }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .control])
            Button(L10n.text(.moveTabRight)) { workspace?.moveSelectedTab(by: 1) }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .control])
            Button(L10n.text(.moveTabUp)) { workspace?.moveSelectedTab(by: -1) }
                .keyboardShortcut(.upArrow, modifiers: [.command, .control])
            Button(L10n.text(.moveTabDown)) { workspace?.moveSelectedTab(by: 1) }
                .keyboardShortcut(.downArrow, modifiers: [.command, .control])
            Divider()
        }
    }
}
