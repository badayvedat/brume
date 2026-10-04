import AppKit
import BrumeCore
import GhosttyTerminal
import SwiftUI

/// Les « ... » de la barre : ouvrir le dossier du terminal affiché ailleurs, copier son chemin,
/// passer aux onglets verticaux, ouvrir les réglages.
struct MoreMenu: View {
    @ObservedObject var state: TerminalViewState
    let workspace: TerminalWorkspace

    @State private var isHovered = false
    @State private var anchor = MenuAnchor()
    @Environment(SettingsStore.self) private var settings

    private var folder: URL? {
        state.workingDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    var body: some View {
        Button(action: showMenu) {
            // Pas de symbole vertical dans macOS : l'horizontal, tourné.
            SystemSymbol.image("ellipsis", size: 13, weight: .medium)
                .rotationEffect(.degrees(90))
                .foregroundStyle(isHovered ? Ink.text : Ink.muted)
                .frame(width: BarButton.size, height: BarButton.size)
                .background(isHovered ? Ink.selection : .clear, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .menuAnchor(anchor)
        .accessibilityLabel(L10n.text(.moreOptions))
        .tooltip(L10n.text(.moreOptions))
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
    }

    private func showMenu() {
        guard let view = anchor.view else { return }
        var entries: [MenuEntry] = []
        if let folder {
            if let finder = InstalledApps.finder {
                entries.append(.item(L10n.text(.showInFinder), icon: finder.icon) { finder.open(folder) })
            }
            for editor in InstalledApps.editors {
                entries.append(.item("\(L10n.text(.openIn)) \(editor.name)", icon: editor.icon) { editor.open(folder) })
            }
            entries.append(.separator)
            entries.append(.item(L10n.text(.copyPath)) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(folder.path, forType: .string)
            })
        } else {
            entries.append(.item(L10n.text(.noFolderYet), enabled: false) {})
        }
        entries.append(.separator)
        entries.append(.item(L10n.text(.verticalTabs), shortcut: settings.shortcutLabel(.verticalTabs), checked: settings.verticalTabs.isOn) {
            settings.verticalTabs.isOn.toggle()
        })
        entries.append(.item("\(L10n.text(.settings))…", shortcut: "⌘,") { workspace.showSettings() })
        PopupMenu.show(entries, below: view)
    }
}
