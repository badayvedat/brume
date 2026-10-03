import SwiftUI

extension AnyTransition {
    /// En accordéon : ce qui arrive s'ouvre depuis zéro et pousse ses voisins, ce qui part se
    /// referme. Sans fondu : un onglet qui arrive actif l'est dès qu'on le voit.
    static func collapse(_ axis: Axis) -> AnyTransition {
        .modifier(active: Collapse(axis: axis, isCollapsed: true), identity: Collapse(axis: axis, isCollapsed: false))
    }
}

private struct Collapse: ViewModifier {
    let axis: Axis
    let isCollapsed: Bool

    func body(content: Content) -> some View {
        content
            .frame(
                width: axis == .horizontal && isCollapsed ? 0 : nil,
                height: axis == .vertical && isCollapsed ? 0 : nil,
                alignment: .topLeading
            )
            .clipped()
    }
}
