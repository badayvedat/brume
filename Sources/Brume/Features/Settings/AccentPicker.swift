import BrumeCore
import SwiftUI

/// Les pastilles de Monocode, une par couleur.
struct AccentPicker: View {
    @Binding var accent: Accent

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Accent.allCases, id: \.self) { color in
                let isSelected = accent == color
                Button { accent = color } label: {
                    Circle()
                        .fill(Color(hex: color.swatchHex))
                        .overlay { if color == .black { Circle().strokeBorder(Ink.white(0.25)) } }
                        .frame(width: 14, height: 14)
                        .overlay {
                            if isSelected { Circle().strokeBorder(Ink.white(0.8), lineWidth: 2).frame(width: 19, height: 19) }
                        }
                        .frame(width: 20, height: 20)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .tooltip(color.label)
                .accessibilityLabel(color.label)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

private extension Accent {
    @MainActor var label: String {
        switch self {
        case .brume: L10n.text(.colorDefault)
        case .black: L10n.text(.colorBlack)
        case .blue: L10n.text(.colorBlue)
        case .violet: L10n.text(.colorPurple)
        case .pink: L10n.text(.colorPink)
        case .red: L10n.text(.colorRed)
        case .orange: L10n.text(.colorOrange)
        case .yellow: L10n.text(.colorYellow)
        case .green: L10n.text(.colorGreen)
        case .teal: L10n.text(.colorTeal)
        }
    }
}
