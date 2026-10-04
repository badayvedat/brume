import AppKit
import BrumeCore
import SwiftUI

/// Le titre d'un onglet, coupé par `TabTitle.truncated` plutôt que par SwiftUI.
struct TabTitleText: View {
    let title: String
    /// Celle de la police système appliquée autour, pour mesurer le texte.
    let size: CGFloat

    @State private var width: CGFloat = 0

    var body: some View {
        Text(width > 0 ? TabTitle.truncated(title, fitting: width, measure: measure) : title)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
            .accessibilityLabel(title)
    }

    private func measure(_ text: String) -> Double {
        ceil((text as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: size)]).width)
    }
}
