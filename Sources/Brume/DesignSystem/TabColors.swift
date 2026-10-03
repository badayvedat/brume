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
