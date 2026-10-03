import BrumeCore
import SwiftUI

/// Le mot tel qu'il sortira dans le terminal, sans lancer fastfetch à chaque lettre tapée.
struct WordPreview: View {
    let text: String
    let placeholder: String
    let size: WelcomeSize
    let accent: Accent
    let background: String
    /// En verre, pas de fond : la fenêtre floutée passe dessous, comme sous les terminaux.
    let isGlass: Bool

    var body: some View {
        let pixels = PixelFont.banner(text, scale: size.textScale)
        let colors = PixelArt.colors(accent)
        Canvas { context, canvas in
            guard let width = pixels.first?.count, width > 0 else { return }
            let side = min(canvas.width * 0.85 / CGFloat(width), canvas.height * 0.7 / CGFloat(pixels.count), 6)
            let origin = CGPoint(
                x: (canvas.width - side * CGFloat(width)) / 2,
                y: (canvas.height - side * CGFloat(pixels.count)) / 2
            )
            for (y, row) in pixels.enumerated() {
                for (x, pixel) in row.enumerated() {
                    guard let hex = colors[pixel] else { continue }
                    let rect = CGRect(x: origin.x + CGFloat(x) * side, y: origin.y + CGFloat(y) * side, width: side, height: side)
                    context.fill(Path(rect.insetBy(dx: -0.25, dy: -0.25)), with: .color(Color(hex: hex)))
                }
            }
        }
        .overlay {
            if pixels.isEmpty {
                Text(placeholder)
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.disabled)
            }
        }
        .background(isGlass ? .clear : Color(hex: background), in: .rect(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Ink.border) }
        .animation(Ink.slide, value: size)
        .accessibilityHidden(true)
    }
}
