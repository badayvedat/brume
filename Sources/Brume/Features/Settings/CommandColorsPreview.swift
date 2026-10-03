import BrumeCore
import SwiftUI

/// Quelques lignes de terminal colorées comme le fera zsh : commande reconnue en vert, inconnue
/// en rouge, chaînes en jaune, suggestion en gris, dossiers en bleu. On juge la coloration d'un
/// coup d'œil, sans quitter les réglages.
struct CommandColorsPreview: View {
    let colors: ThemeColors
    let font: TerminalFont

    var body: some View {
        let p = colors.palette
        VStack(alignment: .leading, spacing: 4) {
            Text(span("❯ ", p[2]) + span("git", p[2]) + span(" commit -m ", colors.foreground) + span("\"\(L10n.text(.previewMessage))\"", p[3]))
            Text(span("❯ ", p[2]) + span("lsx", p[1]) + span(" -la", p[8]))
            Text(bold("Sources/  Tests/  ", p[4]) + bold("build.sh  ", p[2]) + span("\(L10n.text(.previewLink))  ", p[6]) + span("README.md", colors.foreground))
            Text(span("error: ", p[1]) + span("build failed  ", colors.foreground) + span("warning: ", p[3]) + span("unused", colors.foreground))
        }
        .font(.custom(font.family ?? TerminalFont.defaultFamily, size: 12))
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: colors.background), in: .rect(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Ink.border) }
        .animation(Ink.feedback, value: colors)
        .accessibilityHidden(true)
    }

    private func span(_ text: String, _ hex: String) -> AttributedString {
        var string = AttributedString(text)
        string.foregroundColor = Color(hex: hex)
        return string
    }

    private func bold(_ text: String, _ hex: String) -> AttributedString {
        var string = span(text, hex)
        string.inlinePresentationIntent = .stronglyEmphasized
        return string
    }
}
