import BrumeCore
import SwiftUI

/// Les réglages à la place des terminaux, comme Monocode : la barre latérale des pages à gauche,
/// la page à droite. Échap ou « Retour » ramène aux terminaux.
struct SettingsPage: View {
    let workspace: TerminalWorkspace
    let section: SettingsSection
    let titlebar: WindowTitlebar

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Ink.rule.frame(width: 1)
            VStack(spacing: 0) {
                breadcrumb
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
                        switch section {
                        case .general: GeneralSettings()
                        case .appearance: AppearanceSettings()
                        }
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
                .keyboardShortcut(.cancelAction)
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
