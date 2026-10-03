import AppKit
import BrumeCore
import SwiftUI

/// L'écran de démarrage dessiné case par case, comme le ferait le terminal : les demi-blocs du
/// visuel en rectangles (un `Text` laisserait des jours entre les lignes), le reste en texte.
struct WelcomePreview: View {
    let lines: [[AnsiSpan]]
    let colors: ThemeColors
    let font: TerminalFont
    let alignment: WelcomeAlignment

    @State private var size: CGSize = .zero

    private static let padding: CGFloat = 14

    var body: some View {
        let metrics = Metrics(
            family: font.family ?? TerminalFont.defaultFamily,
            columns: contentColumns,
            rows: lines.count,
            space: CGSize(width: size.width - Self.padding * 2, height: size.height - Self.padding * 2)
        )
        // Une case fixe : le rendu se réduit pour y tenir, et le nouveau remplace l'ancien en fondu.
        ZStack {
            Canvas { context, canvas in
                draw(in: &context, metrics: metrics, columns: Int(canvas.width / metrics.cell.width))
            }
            .frame(height: CGFloat(lines.count) * metrics.cell.height)
            .id(lines)
            .transition(.opacity)
        }
        .padding(Self.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: colors.background), in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Ink.border) }
        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lines.map { $0.map(\.text).joined().trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: "\n"))
    }

    /// La largeur visible la plus grande, sans les espaces de fin : comme le calcule le shell.
    private var contentColumns: Int {
        lines.map { line in
            let text = line.map(\.text).joined()
            return text.count - text.reversed().prefix { $0 == " " }.count
        }.max() ?? 0
    }

    private func draw(in context: inout GraphicsContext, metrics: Metrics, columns: Int) {
        let offset = switch alignment {
        case .left: 2
        case .center: (columns - contentColumns) / 2
        case .right: columns - contentColumns - 2
        }
        let cell = metrics.cell
        for (row, line) in lines.enumerated() {
            var column = max(offset, 0)
            for span in line {
                let foreground = color(span.foreground) ?? Color(hex: colors.foreground)
                let background = color(span.background)
                var run = ""
                var runStart = column
                func flush() {
                    guard !run.isEmpty else { return }
                    var text = Text(run).font(.custom(metrics.family, size: metrics.size)).foregroundColor(foreground)
                    if span.isBold { text = text.bold() }
                    context.draw(text, at: CGPoint(x: CGFloat(runStart) * cell.width, y: CGFloat(row) * cell.height), anchor: .topLeading)
                    run = ""
                }
                for character in span.text {
                    let rect = CGRect(x: CGFloat(column) * cell.width, y: CGFloat(row) * cell.height, width: cell.width, height: cell.height)
                    if let background {
                        context.fill(Path(rect.insetBy(dx: -0.25, dy: -0.25)), with: .color(background))
                    }
                    if let half = halfBlock(character) {
                        flush()
                        let shape = switch half {
                        case .top: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2)
                        case .bottom: CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2)
                        case .full: rect
                        }
                        // Un quart de point de plus : sans, des jours apparaissent entre les cases.
                        context.fill(Path(shape.insetBy(dx: -0.25, dy: -0.25)), with: .color(foreground))
                        runStart = column + 1
                    } else {
                        if run.isEmpty { runStart = column }
                        run.append(character)
                    }
                    column += 1
                }
                flush()
            }
        }
    }

    private enum Half { case top, bottom, full }

    private func halfBlock(_ character: Character) -> Half? {
        switch character {
        case "▀": .top
        case "▄": .bottom
        case "█": .full
        default: nil
        }
    }

    private func color(_ color: AnsiColor?) -> Color? {
        switch color {
        case let .palette(index) where index < colors.palette.count: Color(hex: colors.palette[index])
        case let .rgb(hex): Color(hex: hex)
        default: nil
        }
    }

    /// La taille d'une case : la police à 11 points, réduite pour que la page tienne dans l'aperçu.
    private struct Metrics {
        let family: String
        let size: CGFloat
        let cell: CGSize

        init(family: String, columns: Int, rows: Int, space: CGSize) {
            self.family = family
            let reference = NSFont(name: family, size: 10) ?? .monospacedSystemFont(ofSize: 10, weight: .regular)
            let advance = ("M" as NSString).size(withAttributes: [.font: reference]).width / 10
            let lineHeight = (reference.ascender - reference.descender + reference.leading) / 10
            var fitting: CGFloat = 11
            if columns > 0, space.width > 0 { fitting = min(fitting, space.width / (CGFloat(columns + 4) * advance)) }
            if rows > 0, space.height > 0 { fitting = min(fitting, space.height / (CGFloat(rows + 2) * lineHeight)) }
            size = max(3, fitting)
            let font = NSFont(name: family, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
            cell = CGSize(width: advance * size, height: font.ascender - font.descender + font.leading)
        }
    }
}

/// L'aperçu ouvert depuis l'en-tête « Contenu » : fastfetch lancé à l'ouverture.
struct WelcomePreviewPanel: View {
    @Environment(SettingsStore.self) private var settings
    @State private var lines: [[AnsiSpan]] = []

    var body: some View {
        WelcomePreview(
            lines: lines,
            colors: TerminalThemes.colors(for: settings.appearance),
            font: settings.font,
            alignment: settings.welcome.alignment
        )
        .frame(maxWidth: 720, maxHeight: 360)
        .task {
            let output = await settings.welcomePreview()
            withAnimation(Ink.slide) { lines = output }
        }
    }
}
