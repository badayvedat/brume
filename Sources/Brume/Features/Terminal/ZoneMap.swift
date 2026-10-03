import BrumeCore
import SwiftUI

/// Les splits d'un onglet en miniature, celui de `pane` plein : dans un groupe de la barre
/// latérale, on voit où chacun s'affiche.
struct ZoneMap: View {
    let tree: SplitTree<UUID>
    let pane: UUID
    let isFocused: Bool

    @Environment(\.accent) private var accent

    var body: some View {
        Canvas { context, size in
            for (other, frame) in tree.frames(in: CGRect(origin: .zero, size: size)) {
                let shape = Path(roundedRect: frame.insetBy(dx: 1, dy: 1), cornerRadius: 1.5)
                if other == pane {
                    context.fill(shape, with: .color(isFocused ? accent.color : Ink.muted))
                } else {
                    context.stroke(shape, with: .color(Ink.disabled), lineWidth: 1)
                }
            }
        }
        .frame(width: 20, height: 14)
        .accessibilityHidden(true)
    }
}
