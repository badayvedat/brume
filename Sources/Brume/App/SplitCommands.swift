import BrumeCore
import SwiftUI

struct SplitCommands: Commands {
    @FocusedValue(\.terminalWorkspace) private var workspace
    let settings: SettingsStore

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Divider()
            Button(L10n.text(.splitRight)) { workspace?.showingTerminals { $0.split(.horizontal) } }
                .keyboardShortcut(settings.keyboardShortcut(.splitRight))
            Button(L10n.text(.splitDown)) { workspace?.showingTerminals { $0.split(.vertical) } }
                .keyboardShortcut(settings.keyboardShortcut(.splitDown))
            Button(L10n.text(.leaveGroup)) { workspace?.showingTerminals { $0.detach($0.focusedID) } }
                .disabled(workspace?.isSplit != true)
            Button(L10n.text(.ungroup)) { workspace?.showingTerminals { $0.separate($0.layout.selectedTab) } }
                .disabled(workspace?.isSplit != true)
        }
        CommandGroup(before: .windowArrangement) {
            Button(L10n.text(.focusPreviousSplit)) { workspace?.showingTerminals { $0.focusPrevious() } }
                .keyboardShortcut(settings.keyboardShortcut(.focusPreviousSplit))
            Button(L10n.text(.focusNextSplit)) { workspace?.showingTerminals { $0.focusNext() } }
                .keyboardShortcut(settings.keyboardShortcut(.focusNextSplit))
            Button(L10n.text(.focusSplitLeft)) { workspace?.showingTerminals { $0.focus(toward: .left) } }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
            Button(L10n.text(.focusSplitRight)) { workspace?.showingTerminals { $0.focus(toward: .right) } }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
            Button(L10n.text(.focusSplitUp)) { workspace?.showingTerminals { $0.focus(toward: .up) } }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])
            Button(L10n.text(.focusSplitDown)) { workspace?.showingTerminals { $0.focus(toward: .down) } }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])
            Button(L10n.text(.equalizeSplits)) { workspace?.showingTerminals { $0.equalizeSplits() } }
                .keyboardShortcut(settings.keyboardShortcut(.equalizeSplits))
            Toggle(L10n.text(.zoomSplit), isOn: Binding(
                get: { workspace?.zoomedPane != nil },
                set: { _ in workspace?.showingTerminals { $0.toggleZoom() } }
            ))
            .keyboardShortcut(settings.keyboardShortcut(.zoomSplit))
            .disabled(workspace?.isSplit != true)
            Divider()
            // Les flèches suivent la barre d'onglets : gauche et droite en haut, haut et bas sur le côté.
            if settings.verticalTabs.isOn {
                Button(L10n.text(.moveTabUp)) { workspace?.showingTerminals { $0.moveSelectedTab(by: -1) } }
                    .keyboardShortcut(.upArrow, modifiers: [.command, .control])
                Button(L10n.text(.moveTabDown)) { workspace?.showingTerminals { $0.moveSelectedTab(by: 1) } }
                    .keyboardShortcut(.downArrow, modifiers: [.command, .control])
            } else {
                Button(L10n.text(.moveTabLeft)) { workspace?.showingTerminals { $0.moveSelectedTab(by: -1) } }
                    .keyboardShortcut(.leftArrow, modifiers: [.command, .control])
                Button(L10n.text(.moveTabRight)) { workspace?.showingTerminals { $0.moveSelectedTab(by: 1) } }
                    .keyboardShortcut(.rightArrow, modifiers: [.command, .control])
            }
            Divider()
        }
    }
}
