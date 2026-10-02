import BrumeCore
import GhosttyTerminal
import SwiftUI

struct TerminalSplitView: View {
    static let space = "terminal-splits"

    let workspace: TerminalWorkspace

    var body: some View {
        GeometryReader { geometry in
            let bounds = CGRect(origin: .zero, size: geometry.size)
            let frames = workspace.tree.frames(in: bounds)
            // Tous les volets au même niveau, rangés par identifiant : SwiftUI garde chaque
            // vue quand l'arbre change. Une vue recréée tuerait le shell qu'elle porte.
            ZStack(alignment: .topLeading) {
                ForEach(workspace.tree.panes, id: \.self) { id in
                    if let state = workspace.states[id], let frame = frames[id] {
                        TerminalPane(
                            state: state,
                            dimmed: workspace.isSplit && id != workspace.focusedID,
                            onFocus: { workspace.didFocus(id) }
                        )
                        .frame(width: frame.width, height: frame.height)
                        .offset(x: frame.minX, y: frame.minY)
                    }
                }
                // Identifiées par leur place dans l'arbre : stable pendant un glissé.
                ForEach(workspace.tree.dividers(in: bounds), id: \.path) { divider in
                    SplitHandle(divider: divider) { workspace.setRatio($0, at: divider.path) }
                }
            }
            .coordinateSpace(.named(Self.space))
        }
    }
}

private struct SplitHandle: View {
    let divider: SplitDivider
    let onDrag: (CGFloat) -> Void

    /// Plus large que le trait d'un point, pour l'attraper sans viser.
    private let grip: CGFloat = 6

    var body: some View {
        let line = divider.line
        let isVertical = divider.axis == .horizontal
        ZStack {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: isVertical ? 1 : nil, height: isVertical ? nil : 1)
        }
        .frame(width: isVertical ? grip : line.width, height: isVertical ? line.height : grip)
        .contentShape(Rectangle())
        .pointerStyle(isVertical ? .columnResize : .rowResize)
        .offset(x: isVertical ? line.minX - grip / 2 : line.minX, y: isVertical ? line.minY : line.minY - grip / 2)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(TerminalSplitView.space))
                .onChanged { onDrag(divider.ratio(at: $0.location)) }
        )
    }
}

private struct TerminalPane: View {
    @ObservedObject var state: TerminalViewState
    let dimmed: Bool
    let onFocus: () -> Void

    var body: some View {
        TerminalSurfaceView(context: state)
            // Comme Ghostty : le volet inactif est légèrement assombri.
            .overlay {
                if dimmed {
                    Color.black.opacity(0.3).allowsHitTesting(false)
                }
            }
            .overlay {
                ScrollbarOverlay(
                    position: state.scrollbar.map {
                        ScrollbarPosition(total: Int($0.total), offset: Int($0.offset), visible: Int($0.len))
                    },
                    isDark: state.backgroundColor.isDark,
                    onScroll: { state.attachedPlatformView?.scrollWheel(with: $0) },
                    onScrollToRow: { state.surface?.scrollToRow(UInt($0)) }
                )
            }
            .onChange(of: state.isFocused) { _, isFocused in
                if isFocused { onFocus() }
            }
    }
}

/// Titre et couleur de la fenêtre, pris sur le terminal qui a le focus.
struct TerminalWindowChrome: ViewModifier {
    @ObservedObject var state: TerminalViewState

    func body(content: Content) -> some View {
        content
            .navigationTitle(state.title)
            // La barre de titre prend la couleur du terminal, comme dans Ghostty.
            .containerBackground(Color(state.backgroundColor), for: .window)
    }
}

private extension TerminalColor {
    var isDark: Bool {
        0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue) < 128
    }
}
