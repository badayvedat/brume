import BrumeCore
import SwiftUI

/// Un preset à cliquer, avec un aperçu de la fenêtre : on choisit sur ce qu'on voit.
struct PresetCard: View {
    let preset: TranslucencyPreset
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                preview
                    .frame(height: 84)
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(isHovered ? 0.3 : 0.12), lineWidth: isSelected ? 2 : 1)
                    }
                Text(L10n.text(preset.label))
                    .font(.headline)
                Text(L10n.text(preset.hint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { isHovered = $0 }
    }

    private var preview: some View {
        ZStack(alignment: .topLeading) {
            if preset == .glass {
                LinearGradient(colors: [.purple, .indigo, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(.orange).frame(width: 50).offset(x: 110, y: 30).blur(radius: 12)
                Color.black.opacity(0.5)
            } else {
                Color(white: 0.12)
            }
            VStack(alignment: .leading, spacing: 5) {
                ForEach([0.7, 0.45, 0.55], id: \.self) { width in
                    Capsule().fill(.white.opacity(0.75)).frame(width: 130 * width, height: 4)
                }
            }
            .padding(12)
        }
        .accessibilityHidden(true)
    }
}

extension TranslucencyPreset {
    var label: TextKey {
        switch self {
        case .normal: .styleNormal
        case .glass: .styleGlass
        }
    }

    var hint: TextKey {
        switch self {
        case .normal: .styleNormalHint
        case .glass: .styleGlassHint
        }
    }
}
