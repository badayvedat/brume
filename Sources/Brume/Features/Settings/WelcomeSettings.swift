import BrumeCore
import SwiftUI

/// L'écran de démarrage des terminaux : l'en-tête choisi en haut, puis le visuel à gauche et le texte
/// à droite, la carte inutile estompée. Comme dans Monocode, rien n'apparaît ni ne disparaît : la
/// page ne bouge jamais.
struct WelcomeSettings: View {
    let section: SettingsSection
    let onPreview: () -> Void

    @Environment(SettingsStore.self) private var settings
    @State private var width: CGFloat = 0

    /// En dessous, la carte du texte passe sous celle du visuel.
    private static let sideBySideWidth: CGFloat = 640

    var body: some View {
        @Bindable var settings = settings
        let welcome = settings.welcome
        SettingsScroll(section: section) {
            SettingsGroup(title: L10n.text(.welcomePage)) {
                SettingsRow(title: L10n.text(.showWelcome), hint: L10n.text(.welcomePageHint), isLast: true) {
                    Switch(label: L10n.text(.showWelcome), isOn: $settings.welcome.isEnabled)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 16) {
                    SettingsHeader(title: L10n.text(.content), hint: L10n.text(.contentHint))
                        .opacity(welcome.isEnabled ? 1 : 0.4)
                    Spacer()
                    previewButton
                }
                VStack(spacing: 16) {
                    SettingsCard {
                        SettingsRow(title: L10n.text(.showContent), hint: L10n.text(.showContentHint)) {
                            Segmented(
                                label: L10n.text(.showContent),
                                options: WelcomeContent.allCases.map { ($0, L10n.text($0.title)) },
                                selection: $settings.welcome.content
                            )
                        }
                        SettingsRow(title: L10n.text(.welcomeSize), hint: L10n.text(.welcomeSizeHint), isLast: true) {
                            Segmented(
                                label: L10n.text(.welcomeSize),
                                options: WelcomeSize.allCases.map { ($0, L10n.text($0.title)) },
                                selection: $settings.welcome.size
                            )
                        }
                    }
                    Group {
                        // Deux cartes de même hauteur : la grille des visuels et le rendu du mot s'étirent.
                        if width >= Self.sideBySideWidth {
                            HStack(alignment: .top, spacing: 16) {
                                visualCard
                                textCard
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        } else {
                            VStack(spacing: 16) {
                                visualCard
                                textCard
                            }
                        }
                    }
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
                }
                .disabled(!welcome.isEnabled)
                .opacity(welcome.isEnabled ? 1 : 0.4)
            }
            SettingsGroup(title: L10n.text(.informationGroup), hint: L10n.text(.informationGroupHint)) {
                SettingsRow(title: L10n.text(.information), hint: L10n.text(.informationHint)) {
                    Segmented(
                        label: L10n.text(.information),
                        options: WelcomeInfo.allCases.map { ($0, L10n.text($0.title)) },
                        selection: $settings.welcome.info
                    )
                }
                SettingsRow(title: L10n.text(.position), hint: L10n.text(.positionHint), isLast: true) {
                    Segmented(
                        label: L10n.text(.position),
                        options: WelcomeAlignment.allCases.map { ($0, L10n.text($0.title)) },
                        selection: $settings.welcome.alignment
                    )
                }
            }
            .disabled(!welcome.isEnabled)
            .opacity(welcome.isEnabled ? 1 : 0.4)
        }
        .animation(Ink.slide, value: welcome.isEnabled)
        .animation(Ink.slide, value: welcome.content)
    }

    private var previewButton: some View {
        Button(action: onPreview) {
            HStack(spacing: 6) {
                SystemSymbol.image("eye", size: 12)
                Text(L10n.text(.showPreview))
            }
        }
        .buttonStyle(.secondary)
        .accessibilityLabel(L10n.text(.showPreview))
    }

    private var visualCard: some View {
        @Bindable var settings = settings
        let isActive = settings.welcome.showsVisual
        return SettingsCard {
            SettingsStackedRow(title: L10n.text(.visual), hint: L10n.text(.visualHint), isLast: true) {
                VisualPicker(selection: $settings.welcome.visual, palette: TerminalThemes.colors(for: settings.appearance).palette)
                    .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .disabled(!isActive)
        // Écran coupé, le groupe entier est déjà estompé : pas une seconde fois.
        .opacity(isActive || !settings.welcome.isEnabled ? 1 : 0.4)
    }

    private var textCard: some View {
        @Bindable var settings = settings
        let isActive = settings.welcome.content != .visual
        let limit = settings.welcome.size.textLimit
        return SettingsCard {
            SettingsStackedRow(title: L10n.text(.welcomeText), hint: L10n.text(.welcomeTextHint)) {
                HStack(spacing: 10) {
                    Field(
                        label: L10n.text(.welcomeText),
                        placeholder: L10n.text(.welcomeTextPlaceholder),
                        text: $settings.welcome.text,
                        limit: limit
                    )
                    // Au-delà, après un passage à une taille plus grande, le mot s'affiche coupé.
                    let count = settings.welcome.text.count
                    Text("\(count) / \(limit) \(L10n.text(.characters))")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(count > limit ? Ink.warning : Ink.meta)
                }
            }
            WordPreview(
                text: settings.welcome.displayedText(at: settings.welcome.size),
                placeholder: L10n.text(.welcomeTextPlaceholder),
                size: settings.welcome.size,
                accent: settings.appearance.accent,
                background: TerminalThemes.colors(for: settings.appearance).background
            )
            .frame(minHeight: 96, maxHeight: .infinity)
            .padding(16)
        }
        .disabled(!isActive)
        .opacity(isActive || !settings.welcome.isEnabled ? 1 : 0.4)
    }
}
