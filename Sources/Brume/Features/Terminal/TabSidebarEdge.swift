import BrumeCore
import SwiftUI

/// Le bord droit de la barre : un trait, à la couleur d'accent au survol, qu'on glisse pour
/// changer la largeur. La prise reste côté barre : la première colonne du terminal se sélectionne.
struct TabSidebarEdge: View {
    let width: CGFloat
    let onResize: (CGFloat) -> Void
    let onResizeEnd: () -> Void

    @State private var isHovered = false
    /// La largeur au début du glisser : le bord suit la souris sans sauter jusqu'à elle.
    @State private var startWidth: CGFloat?
    @Environment(\.accent) private var accent

    private var isActive: Bool {
        isHovered || startWidth != nil
    }

    var body: some View {
        Rectangle()
            .fill(isActive ? accent.color : Ink.rule)
            .frame(width: isActive ? 2 : 1)
            .frame(width: 8, alignment: .trailing)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            // Le trait se pose dans la colonne laissée entre la barre et les terminaux.
            .offset(x: 1)
            .pointerStyle(.columnResize)
            .onHover { hovering in
                withAnimation(Ink.motion(.easeOut(duration: 0.12))) { isHovered = hovering }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(TerminalScreen.space))
                    .onChanged { value in
                        let start = startWidth ?? width
                        startWidth = start
                        onResize(Self.clamped(start + value.translation.width))
                    }
                    .onEnded { _ in
                        startWidth = nil
                        onResizeEnd()
                    }
            )
            .accessibilityElement()
            .accessibilityLabel(L10n.text(.sidebarWidth))
            .accessibilityValue("\(Int(width))")
            .accessibilityAdjustableAction { direction in
                onResize(Self.clamped(width + (direction == .increment ? 20 : -20)))
                onResizeEnd()
            }
    }

    private static func clamped(_ width: CGFloat) -> CGFloat {
        min(max(width, VerticalTabs.widthRange.lowerBound), VerticalTabs.widthRange.upperBound)
    }
}
