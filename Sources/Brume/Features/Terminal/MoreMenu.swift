import AppKit
import BrumeCore
import GhosttyTerminal
import SwiftUI

/// Les « ... » de la barre : ouvrir le dossier du terminal affiché ailleurs, copier son chemin,
/// choisir le style de la fenêtre, réinitialiser les onglets.
struct MoreMenu: View {
    @ObservedObject var state: TerminalViewState
    let workspace: TerminalWorkspace

    @State private var isHovered = false
    @Environment(SettingsStore.self) private var settings

    private var folder: URL? {
        state.workingDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    var body: some View {
        Menu {
            if let folder {
                if let finder = InstalledApps.finder {
                    item(L10n.text(.showInFinder), icon: finder.icon) { finder.open(folder) }
                }
                ForEach(InstalledApps.editors) { editor in
                    item("\(L10n.text(.openIn)) \(editor.name)", icon: editor.icon) { editor.open(folder) }
                }
                Divider()
                Button(L10n.text(.copyPath)) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(folder.path, forType: .string)
                }
            } else {
                Text(L10n.text(.noFolderYet))
            }
            Divider()
            // En attendant la fenêtre de réglages.
            Picker(L10n.text(.windowStyle), selection: preset) {
                ForEach(TranslucencyPreset.allCases, id: \.self) { preset in
                    Text(L10n.text(preset.label)).tag(Optional(preset))
                }
            }
            Divider()
            Button(L10n.text(.resetTabs), action: workspace.reset)
        } label: {
            // Pas de symbole vertical dans macOS : l'horizontal, tourné.
            SystemSymbol.image("ellipsis", size: 13, weight: .medium)
                .rotationEffect(.degrees(90))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: BarButton.size, height: BarButton.size)
                .background(isHovered ? Color.primary.opacity(0.1) : .clear, in: .rect(cornerRadius: 7))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel(L10n.text(.moreOptions))
        .tooltip(L10n.text(.moreOptions))
        .onHover { isHovered = $0 }
    }

    private var preset: Binding<TranslucencyPreset?> {
        Binding {
            TranslucencyPreset(matching: settings.translucency)
        } set: {
            if let preset = $0 { settings.setTranslucency(preset.translucency) }
        }
    }

    private func item(_ title: String, icon: NSImage, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label { Text(title) } icon: { Image(nsImage: icon) }
        }
    }
}

private extension TranslucencyPreset {
    var label: TextKey {
        switch self {
        case .normal: .styleNormal
        case .glass: .styleGlass
        }
    }
}
