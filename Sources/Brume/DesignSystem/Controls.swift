import BrumeCore
import SwiftUI

// Les contrôles de Brume aux mesures de Monocode : compacts, bordés de blanc à 10 %, sans ombre.

/// Interrupteur de 36 × 20, à l'accent quand il est allumé. Avec le noir, dont l'accent est
/// blanc, le bleu des pastilles : une pastille blanche sur une piste blanche ne se verrait pas.
struct Switch: View {
    let label: String
    @Binding var isOn: Bool

    @Environment(\.accent) private var accent

    var body: some View {
        Button { isOn.toggle() } label: {
            Capsule()
                .fill(isOn ? (accent.isNeutral ? Accent.blue.color : accent.color) : Ink.white(0.2))
                .frame(width: 36, height: 20)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle().fill(.white).frame(width: 16, height: 16).padding(2)
                }
                .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.15), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "1" : "0")
        .accessibilityAddTraits(.isToggle)
    }
}

/// Quelques choix côte à côte, celui retenu sur un fond blanc à 10 %.
struct Segmented<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { option in
                Segment(label: option.label, isSelected: selection == option.value) { selection = option.value }
            }
        }
        .padding(2)
        .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(Ink.border) }
        .fixedSize()
    }
}

private struct Segment: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(isSelected || isHovered ? Ink.text : Ink.muted)
                .padding(.horizontal, 10)
                .frame(minWidth: 56, minHeight: 26)
                .background(isSelected ? Ink.selection : .clear, in: .rect(cornerRadius: 5))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Un choix dans une liste : le bouton montre la valeur, la liste s'ouvre en `PopupMenu`.
struct Select<Value: Hashable>: View {
    let label: String
    let options: [(value: Value, label: String)]
    @Binding var selection: Value

    @State private var anchor = MenuAnchor()
    @State private var isHovered = false

    var body: some View {
        Button(action: open) {
            HStack(spacing: 6) {
                Text(options.first { $0.value == selection }?.label ?? "")
                    .lineLimit(1)
                Spacer(minLength: 0)
                SystemSymbol.image("chevron.down", size: 10, weight: .semibold)
                    .foregroundStyle(Ink.muted)
            }
            .font(.system(size: 12))
            .foregroundStyle(Ink.text)
            .padding(.horizontal, 8)
            .frame(width: 180, height: 28)
            .background(Ink.hover, in: .rect(cornerRadius: 6))
            .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(isHovered ? Ink.white(0.2) : Ink.border) }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .menuAnchor(anchor)
        .onHover { isHovered = $0 }
        .accessibilityLabel(label)
        .accessibilityValue(options.first { $0.value == selection }?.label ?? "")
    }

    private func open() {
        guard let view = anchor.view else { return }
        let entries = options.map { option in
            MenuEntry.item(option.label, checked: option.value == selection) { selection = option.value }
        }
        PopupMenu.show(entries, below: view, width: 220)
    }
}

/// Le bouton secondaire de Monocode : 28 de haut, bordé, le texte s'éclaire au survol.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryButton(configuration: configuration)
    }

    private struct SecondaryButton: View {
        let configuration: Configuration

        @State private var isHovered = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 12))
                .foregroundStyle(isHovered ? Ink.text : Ink.white(0.7))
                .padding(.horizontal, 10)
                .frame(minWidth: 28, minHeight: 28)
                .background(isHovered || configuration.isPressed ? Ink.selection : .clear, in: .rect(cornerRadius: 6))
                .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(Ink.border) }
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(isEnabled ? 1 : 0.4)
                .contentShape(.rect)
                .onHover { isHovered = $0 }
                .animation(Ink.feedback, value: isHovered)
        }
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle {
        SecondaryButtonStyle()
    }
}

/// Le curseur de Monocode : une piste fine en blanc à 15 %, une pastille blanche, la valeur à droite.
struct ValueSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    let display: String

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geometry in
                let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                ZStack(alignment: .leading) {
                    Capsule().fill(Ink.white(0.15)).frame(height: 4)
                    Circle()
                        .fill(Ink.text)
                        .frame(width: 12, height: 12)
                        .offset(x: (geometry.size.width - 12) * fraction)
                }
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
                .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                    let ratio = min(max((drag.location.x - 6) / (geometry.size.width - 12), 0), 1)
                    let raw = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
                    value = (raw / step).rounded() * step
                })
            }
            .frame(height: 20)
            Text(display)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(Ink.text)
                .frame(width: 40, alignment: .trailing)
        }
        .frame(width: 224)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(display)
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? step : -step
            value = min(max(value + delta, range.lowerBound), range.upperBound)
        }
    }
}
