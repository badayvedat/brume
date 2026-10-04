import BrumeCore
import SwiftUI

/// Les réglages à la place des terminaux, comme Monocode : la barre latérale des pages à gauche,
/// la page à droite. Échap ou « Retour » ramène aux terminaux.
struct SettingsPage: View {
    let workspace: TerminalWorkspace
    let section: SettingsSection
    let titlebar: WindowTitlebar

    @Environment(SettingsStore.self) private var settings

    /// `-BrumePreview YES` au lancement l'ouvre d'emblée, pour le vérifier sans piloter l'interface.
    @State private var showsPreview = UserDefaults.standard.bool(forKey: "BrumePreview")

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Ink.rule.frame(width: 1)
            VStack(spacing: 0) {
                breadcrumb
                switch section {
                case .general: SettingsScroll(section: section) { GeneralSettings() }
                case .appearance: SettingsScroll(section: section) { AppearanceSettings() }
                case .welcome: WelcomeSettings(section: section, onPreview: { showsPreview = true })
                case .shortcuts: SettingsScroll(section: section) { ShortcutsSettings() }
                }
            }
            .overlay {
                if showsPreview && section == .welcome {
                    ModalPanel(
                        title: L10n.text(.preview),
                        background: Color(hex: TerminalThemes.colors(for: settings.appearance).background),
                        onClose: { showsPreview = false }
                    ) {
                        WelcomePreviewPanel()
                    }
                }
            }
        }
        // Une autre page le cacherait sans le fermer : Échap n'y ramènerait plus aux terminaux.
        .onChange(of: section) { showsPreview = false }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(SettingsSection.allCases, id: \.self) { item in
                SidebarItem(icon: item.icon, title: L10n.text(item.title), isSelected: item == section) {
                    workspace.showSettings(item)
                }
            }
            Spacer()
            SidebarItem(icon: "chevron.left", title: L10n.text(.back), isSelected: false, action: workspace.closeSettings)
                .keyboardShortcut(showsPreview ? nil : .cancelAction)
        }
        .padding(.horizontal, 8)
        .padding(.top, titlebar.buttonsCenterY * 2 + 12)
        .padding(.bottom, 8)
        .frame(width: 200)
        .background(Color.black.opacity(0.12))
        .background { WindowDragArea() }
    }

    private var breadcrumb: some View {
        HStack(spacing: 8) {
            Text(L10n.text(.settings)).foregroundStyle(Ink.hint)
            Text("/").foregroundStyle(Ink.white(0.25))
            Text(L10n.text(section.title)).foregroundStyle(Ink.text)
            Spacer()
        }
        .font(.system(size: 13))
        .padding(.horizontal, 12)
        .frame(height: titlebar.buttonsCenterY * 2)
        .background { WindowDragArea() }
        .overlay(alignment: .bottom) { Ink.rule.frame(height: 1) }
    }
}

private struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SystemSymbol.image(icon, size: 14)
                    .frame(width: 16)
                    .opacity(0.7)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .foregroundStyle(isSelected || isHovered ? Ink.text : Ink.muted)
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(isSelected ? Ink.selection : isHovered ? Ink.hover : .clear, in: .rect(cornerRadius: 6))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SettingsScroll<Content: View>: View {
    let section: SettingsSection
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text(section.title))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Ink.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(L10n.text(section.hint))
                        .font(.system(size: 13))
                        .foregroundStyle(Ink.hint)
                        .lineSpacing(4)
                        .frame(maxWidth: 576, alignment: .leading)
                }
                content
            }
            .frame(maxWidth: 1024, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 64)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.never)
        // La barre du haut est transparente : sans ça, la page défile dessous.
        .clipped()
    }
}

// Essayé puis écarté : le verre des barres latérales de macOS sortait de la DA du terminal.
// Pour le remettre, le poser sur le fond de la barre latérale quand l'effet verre est activé.
//
// private struct SidebarGlass: NSViewRepresentable {
//     func makeNSView(context: Context) -> NSVisualEffectView {
//         let view = PassThroughEffectView()
//         view.material = .sidebar
//         view.blendingMode = .behindWindow
//         view.state = .active
//         return view
//     }
//
//     func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
//
//     /// Les clics vont au `WindowDragArea` dessous : la barre latérale déplace toujours la fenêtre.
//     private final class PassThroughEffectView: NSVisualEffectView {
//         override func hitTest(_ point: NSPoint) -> NSView? {
//             nil
//         }
//     }
// }
