import AppKit
import BrumeCore
import SwiftUI

extension TabColor {
    var color: Color {
        Color(nsColor: nsColor)
    }

    @MainActor var name: String {
        let key: TextKey = switch self {
        case .red: .colorRed
        case .orange: .colorOrange
        case .yellow: .colorYellow
        case .green: .colorGreen
        case .blue: .colorBlue
        case .purple: .colorPurple
        }
        return L10n.text(key)
    }

    /// Une pastille pour le menu : un symbole système y sortirait gris, rendu en modèle.
    var swatch: NSImage {
        NSImage(size: NSSize(width: 12, height: 12), flipped: false) { rect in
            nsColor.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
    }

    private var nsColor: NSColor {
        switch self {
        case .red: .systemRed
        case .orange: .systemOrange
        case .yellow: .systemYellow
        case .green: .systemGreen
        case .blue: .systemBlue
        case .purple: .systemPurple
        }
    }
}
