import SwiftUI

extension AnyTransition {
    /// Ce qui arrive s'ouvre en accordéon et pousse ses voisins. Ce qui part s'efface aussitôt, à
    /// son propre rythme, et ses voisins glissent à sa place, comme dans Chrome ou Arc : SwiftUI
    /// garde une vue qui part jusqu'à la fin de l'animation, et ses voisins passeraient dessus.
    static func accordion(_ axis: Axis) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(active: Unfold(axis: axis, isFolded: true), identity: Unfold(axis: axis, isFolded: false)),
            removal: .opacity.animation(Ink.motion(.easeOut(duration: 0.08)))
        )
    }
}

private struct Unfold: ViewModifier {
    let axis: Axis
    let isFolded: Bool

    func body(content: Content) -> some View {
        content
            .frame(
                width: axis == .horizontal && isFolded ? 0 : nil,
                height: axis == .vertical && isFolded ? 0 : nil,
                alignment: .topLeading
            )
            .clipped()
    }
}
