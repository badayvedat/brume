import BrumeCore
import SwiftUI

/// Les réglages, ouverts par Cmd+virgule ou le menu « ... ». D'abord des presets à cliquer,
/// le réglage fin replié dessous : le chemin par défaut reste simple.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var isCustomizing = false

    var body: some View {
        Form {
            Section(L10n.text(.windowStyle)) {
                HStack(spacing: 12) {
                    ForEach(TranslucencyPreset.allCases, id: \.self) { preset in
                        PresetCard(preset: preset, isSelected: TranslucencyPreset(matching: settings.translucency) == preset) {
                            settings.setTranslucency(preset.translucency)
                        }
                    }
                }
                .padding(.vertical, 4)
                DisclosureGroup(L10n.text(.customize), isExpanded: $isCustomizing) {
                    LabeledContent(L10n.text(.opacity)) {
                        Slider(value: opacity, in: Translucency.opacityRange)
                        Text(settings.translucency.opacity, format: .percent.precision(.fractionLength(0)))
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                    LabeledContent(L10n.text(.blur)) {
                        Slider(value: blur, in: Double(Translucency.blurRange.lowerBound) ... Double(Translucency.blurRange.upperBound))
                            .disabled(!settings.translucency.isTranslucent)
                        Text("\(settings.translucency.blur)")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .navigationTitle(L10n.text(.settings))
    }

    private var opacity: Binding<Double> {
        Binding {
            settings.translucency.opacity
        } set: {
            var translucency = settings.translucency
            translucency.opacity = ($0 * 100).rounded() / 100
            settings.setTranslucency(translucency)
        }
    }

    private var blur: Binding<Double> {
        Binding {
            Double(settings.translucency.blur)
        } set: {
            var translucency = settings.translucency
            translucency.blur = Int($0.rounded())
            settings.setTranslucency(translucency)
        }
    }
}
