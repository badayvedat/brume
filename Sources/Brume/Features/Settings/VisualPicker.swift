import BrumeCore
import SwiftUI

/// Les visuels de l'écran de démarrage en vignettes, à la couleur d'accent : on choisit en voyant.
struct VisualPicker: View {
    @Binding var selection: WelcomeVisual
    /// Les 16 couleurs du terminal : le logo Apple y prend ses bandes, comme dans fastfetch.
    let palette: [String]

    @Environment(\.accent) private var accent

    var body: some View {
        // Trois par ligne, et des vignettes qui s'étirent : la grille prend la hauteur de la carte voisine.
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(Array(stride(from: 0, to: WelcomeVisual.allCases.count, by: 3)), id: \.self) { start in
                GridRow {
                    ForEach(WelcomeVisual.allCases[start ..< min(start + 3, WelcomeVisual.allCases.count)], id: \.self) { visual in
                        Tile(visual: visual, isSelected: visual == selection, accent: accent, palette: palette) {
                            withAnimation(Ink.slide) { selection = visual }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(.visual))
    }
}

private struct Tile: View {
    let visual: WelcomeVisual
    let isSelected: Bool
    let accent: Accent
    let palette: [String]
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                thumbnail
                    .frame(width: 56, height: 44)
                Text(L10n.text(visual.title))
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected || isHovered ? Ink.text : Ink.muted)
                    .lineLimit(1)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? Ink.selection : isHovered ? Ink.hover : .clear, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? accent.color : Ink.border, lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
        .accessibilityLabel(L10n.text(visual.title))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder private var thumbnail: some View {
        if let pixels = PixelArt.pixels(for: visual) {
            let colors = PixelArt.colors(accent)
            Canvas { context, size in
                let width = pixels.map(\.count).max() ?? 1
                let side = min(size.width / CGFloat(width), size.height / CGFloat(pixels.count))
                let origin = CGPoint(
                    x: (size.width - side * CGFloat(width)) / 2,
                    y: (size.height - side * CGFloat(pixels.count)) / 2
                )
                for (y, row) in pixels.enumerated() {
                    for (x, pixel) in row.enumerated() {
                        guard let hex = colors[pixel] else { continue }
                        let rect = CGRect(x: origin.x + CGFloat(x) * side, y: origin.y + CGFloat(y) * side, width: side, height: side)
                        // Un quart de point de plus : sans, des jours apparaissent entre les pixels.
                        context.fill(Path(rect.insetBy(dx: -0.25, dy: -0.25)), with: .color(Color(hex: hex)))
                    }
                }
            }
        } else {
            // Vert, jaune, rouge, magenta, bleu : les bandes du logo de fastfetch.
            SystemSymbol.image("apple.logo", size: 32)
                .foregroundStyle(LinearGradient(
                    colors: [2, 3, 1, 5, 4].map { Color(hex: palette[$0]) },
                    startPoint: .top,
                    endPoint: .bottom
                ))
        }
    }
}
