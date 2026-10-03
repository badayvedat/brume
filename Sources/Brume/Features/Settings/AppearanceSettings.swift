import BrumeCore
import SwiftUI

/// La page baigne dans la fenêtre : elle change avec les réglages, pas besoin d'aperçu du fond.
struct AppearanceSettings: View {
    @Environment(SettingsStore.self) private var settings
    @State private var showsPreview = false

    var body: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: 32) {
            SettingsGroup(title: L10n.text(.window), hint: L10n.text(.windowHint)) {
                SettingsRow(title: L10n.text(.glass), hint: L10n.text(.glassHint), isLast: !settings.appearance.isGlass) {
                    Switch(label: L10n.text(.glass), isOn: $settings.appearance.isGlass)
                }
                if settings.appearance.isGlass {
                    SettingsRow(title: L10n.text(.opacity), hint: L10n.text(.opacityHint)) {
                        ValueSlider(
                            label: L10n.text(.opacity), value: $settings.appearance.glassOpacity,
                            range: Appearance.glassOpacityRange, step: 0.01,
                            display: settings.appearance.glassOpacity.formatted(.percent.precision(.fractionLength(0)).locale(L10n.language.locale))
                        )
                    }
                    SettingsRow(title: L10n.text(.blur), hint: L10n.text(.blurHint), isLast: true) {
                        ValueSlider(
                            label: L10n.text(.blur), value: blur,
                            range: Double(Appearance.glassBlurRange.lowerBound) ... Double(Appearance.glassBlurRange.upperBound),
                            display: "\(settings.appearance.glassBlur)"
                        )
                    }
                }
            }
            SettingsGroup(title: L10n.text(.colors), hint: L10n.text(.colorsHint)) {
                SettingsRow(title: L10n.text(.color), hint: L10n.text(.colorHint)) {
                    AccentPicker(accent: $settings.appearance.accent)
                }
                SettingsRow(title: L10n.text(.tint), hint: L10n.text(.tintHint), isLast: true) {
                    Segmented(
                        options: [(Strength.low, L10n.text(.strengthLow)), (.medium, L10n.text(.strengthMedium)), (.high, L10n.text(.strengthHigh))],
                        selection: $settings.appearance.tint
                    )
                    .disabled(settings.appearance.accent.isNeutral)
                    .opacity(settings.appearance.accent.isNeutral ? 0.4 : 1)
                }
            }
            SettingsGroup(title: L10n.text(.text)) {
                SettingsRow(title: L10n.text(.font), hint: L10n.text(.fontHint)) {
                    Select(
                        label: L10n.text(.font),
                        options: [(String?.none, TerminalFont.defaultFamily)] + TerminalFonts.featured.map { (Optional($0), $0) },
                        selection: $settings.font.family
                    )
                }
                SettingsRow(title: L10n.text(.commandColors), hint: L10n.text(.commandColorsHint)) {
                    HStack(spacing: 6) {
                        Select(
                            label: L10n.text(.commandColors),
                            options: CommandColors.allCases.map { ($0, $0.name) },
                            selection: $settings.appearance.commandColors
                        )
                        Button {
                            withAnimation(Ink.open) { showsPreview.toggle() }
                        } label: {
                            SystemSymbol.image(showsPreview ? "eye.slash" : "eye", size: 12)
                        }
                        .buttonStyle(.secondary)
                        .tooltip(L10n.text(showsPreview ? .hidePreview : .showPreview))
                        .accessibilityLabel(L10n.text(showsPreview ? .hidePreview : .showPreview))
                    }
                } below: {
                    // Un simple fondu : en glissant, l'aperçu passerait par-dessus le texte de la ligne.
                    if showsPreview {
                        CommandColorsPreview(colors: TerminalThemes.colors(for: settings.appearance), font: settings.font)
                            .transition(.opacity)
                    }
                }
                SettingsRow(title: L10n.text(.fontSize), hint: L10n.text(.fontSizeHint), isLast: true) {
                    HStack(spacing: 8) {
                        Button { settings.font.size -= 1 } label: { Text("−") }
                            .disabled(settings.font.size <= TerminalFont.sizeRange.lowerBound)
                            .accessibilityLabel(L10n.text(.smaller))
                        Text("\(Int(settings.font.size)) pt")
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(Ink.text)
                            .frame(minWidth: 40)
                        Button { settings.font.size += 1 } label: { Text("+") }
                            .disabled(settings.font.size >= TerminalFont.sizeRange.upperBound)
                            .accessibilityLabel(L10n.text(.larger))
                    }
                    .buttonStyle(.secondary)
                }
            }
        }
        .animation(Ink.feedback, value: settings.appearance.isGlass)
    }

    private var blur: Binding<Double> {
        Binding {
            Double(settings.appearance.glassBlur)
        } set: {
            settings.appearance.glassBlur = Int($0)
        }
    }
}
